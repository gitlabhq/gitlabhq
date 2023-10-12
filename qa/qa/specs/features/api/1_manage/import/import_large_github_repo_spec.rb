# frozen_string_literal: true

require "etc"

# Lifesize project import test executed from https://gitlab.com/gitlab-org/manage/import/import-metrics

# rubocop:disable Rails/Pluck
module QA
  RSpec.describe 'Manage', :github, requires_admin: 'creates users',
    only: { condition: -> { ENV["CI_PROJECT_NAME"] == "import-metrics" } },
    custom_test_metrics: {
      tags: { import_type: ENV["QA_IMPORT_TYPE"], import_repo: ENV["QA_LARGE_IMPORT_REPO"] || "rspec/rspec-core" }
    } do
    describe 'Project import', product_group: :import_and_integrate do # rubocop:disable RSpec/MultipleMemoizedHelpers
      # Full object comparison is a fairly heavy operation
      # Importer itself returns counts of objects it fetched and counts it imported
      # We can use that for a lightweight comparison for very large projects
      let(:only_stats_comparison) { ENV["QA_LARGE_IMPORT_GH_ONLY_STATS_COMPARISON"] == "true" }
      let(:github_repo) { ENV['QA_LARGE_IMPORT_REPO'] || 'rspec/rspec-core' }
      let(:import_max_duration) { ENV['QA_LARGE_IMPORT_DURATION']&.to_i || 7200 }
      let(:api_parallel_threads) { ENV['QA_LARGE_IMPORT_API_PARALLEL']&.to_i || Etc.nprocessors }

      let(:logger) { Runtime::Logger.logger }
      let(:differ) { RSpec::Support::Differ.new(color: true) }
      let(:gitlab_address) { QA::Runtime::Scenario.gitlab_address.chomp("/") }
      let(:dummy_url) { "https://example.com" } # this is used to replace all dynamic urls in descriptions and comments
      let(:api_request_params) { { auto_paginate: true, attempts: 2 } }

      let(:created_by_pattern) { /\*Created by: \S+\*\n\n/ }
      let(:suggestion_pattern) { /suggestion:-\d+\+\d+/ }
      let(:gh_link_pattern) { %r{https://github.com/#{github_repo}/(issues|pull)} }
      let(:gl_link_pattern) { %r{#{gitlab_address}/#{imported_project.path_with_namespace}/-/(issues|merge_requests)} }
      # rubocop:disable Lint/MixedRegexpCaptureTypes
      let(:event_pattern) do
        Regexp.union(
          [
            /(?<event>(un)?assigned)( to)? @\S+/,
            /(?<event>mentioned) in (issue|merge request) [!#]\d+/,
            /(?<event>changed title) from \*\*.*\*\* to \*\*.*\*\*/,
            /(?<event>requested review) from @\w+/,
            /\*(?<event>Merged) by:/,
            /\*\*(Review):\*\*/
          ]
        )
      end
      # rubocop:enable Lint/MixedRegexpCaptureTypes

      # mapping from gitlab to github names
      let(:event_mapping) do
        {
          "label_add" => "labeled",
          "label_remove" => "unlabeled",
          "milestone_add" => "milestoned",
          "milestone_remove" => "demilestoned",
          "assigned" => "assigned",
          "unassigned" => "unassigned",
          "changed title" => "renamed",
          "requested review" => "review_requested",
          "Merged" => "merged"
        }
      end

      # github events that are not migrated or are not correctly mapable in gitlab
      let(:unsupported_events) do
        [
          "head_ref_deleted",
          "head_ref_force_pushed",
          "head_ref_restored",
          "base_ref_force_pushed",
          "base_ref_changed",
          "review_request_removed",
          "review_dismissed",
          "auto_squash_enabled",
          "auto_merge_disabled",
          "comment_deleted",
          "convert_to_draft",
          "ready_for_review",
          "subscribed",
          "unsubscribed",
          "transferred",
          "locked",
          "unlocked",
          "deployed",
          "marked_as_duplicate",
          "unmarked_as_duplicate",
          "connected",
          "disconnected",
          "moved_columns_in_project",
          "added_to_project",
          "removed_from_project",
          "base_ref_deleted",
          "converted_to_discussion",
          # mentions are supported but they can be reported differently on gitlab's side
          # for example mention of issue creation in pr will be reported in the issue on gitlab side
          # or referenced in github will still create a 'mentioned in' comment in gitlab
          "referenced",
          "mentioned"
        ]
      end

      let(:api_client) { Runtime::API::Client.as_admin }

      let(:user) { create(:user, api_client: api_client) }

      let(:github_client) do
        Octokit::Client.new(
          access_token: ENV['QA_LARGE_IMPORT_GH_TOKEN'] || Runtime::Env.github_access_token,
          per_page: 100,
          middleware: Faraday::RackBuilder.new do |builder|
            builder.use(Faraday::Retry::Middleware, exceptions: [Octokit::InternalServerError, Octokit::ServerError])
            builder.use(Faraday::Response::RaiseError) # faraday retry swallows errors, so it needs to be re-raised
          end
        )
      end

      let(:gh_repo) { github_client.repository(github_repo) }

      let(:gh_branches) do
        logger.info("= Fetching branches =")
        with_paginated_request { github_client.branches(github_repo) }.map(&:name)
      end

      let(:gh_commits) do
        logger.info("= Fetching commits =")
        with_paginated_request { github_client.commits(github_repo) }.map(&:sha)
      end

      let(:gh_labels) do
        logger.info("= Fetching labels =")
        with_paginated_request { github_client.labels(github_repo) }.map do |label|
          { name: label.name, color: "##{label.color}" }
        end
      end

      let(:gh_milestones) do
        logger.info("= Fetching milestones =")
        with_paginated_request { github_client.list_milestones(github_repo, state: 'all') }.map do |ms|
          { title: ms.title, description: ms.description }
        end
      end

      let(:gh_all_issues) do
        logger.info("= Fetching issues and prs =")
        with_paginated_request { github_client.list_issues(github_repo, state: 'all') }
      end

      let(:gh_issues) do
        issues = gh_all_issues.reject(&:pull_request).each_with_object({}) do |issue, hash|
          id = issue.number
          hash[id] = {
            url: issue.html_url,
            title: issue.title,
            body: issue.body || '',
            comments: gh_issue_comments[id]
          }
        end

        fetch_github_events(issues, "issue")
      end

      let(:gh_prs) do
        prs = gh_all_issues.select(&:pull_request).each_with_object({}) do |pr, hash|
          id = pr.number
          hash[id] = {
            url: pr.html_url,
            title: pr.title,
            body: pr.body || '',
            comments: [*gh_pr_comments[id], *gh_issue_comments[id]].compact
          }
        end

        fetch_github_events(prs, "pr")
      end

      # rubocop:disable Layout/LineLength
      let(:gh_issue_comments) do
        logger.info("- Fetching issue comments -")
        with_paginated_request { github_client.issues_comments(github_repo) }.each_with_object(Hash.new { |h, k| h[k] = [] }) do |c, hash|
          hash[id_from_url(c.html_url)] << c.body&.gsub(gh_link_pattern, dummy_url)
        end
      end

      let(:gh_pr_comments) do
        logger.info("- Fetching pr comments -")
        with_paginated_request { github_client.pull_requests_comments(github_repo) }.each_with_object(Hash.new { |h, k| h[k] = [] }) do |c, hash|
          hash[id_from_url(c.html_url)] << c.body
            # some suggestions can contain extra whitespaces which gitlab will remove
            &.gsub(/suggestion\s+\r/, "suggestion\r")
            &.gsub(gh_link_pattern, dummy_url)
        end
      end
      # rubocop:enable Layout/LineLength

      let(:imported_project) do
        Resource::ProjectImportedFromGithub.fabricate_via_api! do |project|
          project.add_name_uuid = false
          project.name = 'imported-project'
          project.github_personal_access_token = Runtime::Env.github_access_token
          project.additional_access_tokens = Runtime::Env.github_additional_access_tokens
          project.github_repository_path = github_repo
          project.personal_namespace = user.username
          project.api_client = Runtime::API::Client.new(user: user)
          project.issue_events_import = true
          project.full_notes_import = true
        end
      end

      before do
        QA::Support::Helpers::ImportSource.enable('github')
      end

      after do |example|
        unless defined?(@import_time)
          next save_data_json(test_result_data({
            status: "failed",
            importer: :github,
            import_finished: false,
            import_time: Time.now - @start
          }))
        end

        # add additional import time metric
        example.metadata[:custom_test_metrics][:fields] = { import_time: @import_time }
        # save data for comparison notification creation
        if only_stats_comparison
          next save_data_json(test_result_data({
            status: example.exception ? "failed" : "passed",
            import_time: @import_time,
            import_finished: true,
            errors: imported_project.project_import_status[:failed_relations],
            reported_stats: @stats
          }))
        end

        save_data_json(test_result_data({
          status: example.exception ? "failed" : "passed",
          import_time: @import_time,
          import_finished: true,
          errors: imported_project.project_import_status[:failed_relations],
          reported_stats: @stats,
          source: {
            data: {
              branches: gh_branches.length,
              commits: gh_commits.length,
              labels: gh_labels.length,
              milestones: gh_milestones.length,
              mrs: gh_prs.length,
              mr_comments: gh_prs.sum { |_k, v| v[:comments].length },
              mr_events: gh_prs.sum { |_k, v| v[:events].length },
              issues: gh_issues.length,
              issue_comments: gh_issues.sum { |_k, v| v[:comments].length },
              issue_events: gh_issues.sum { |_k, v| v[:events].length }
            }
          },
          target: {
            project_name: imported_project.path_with_namespace,
            data: {
              branches: gl_branches.length,
              commits: gl_commits.length,
              labels: gl_labels.length,
              milestones: gl_milestones.length,
              mrs: mrs.length,
              mr_comments: mrs.sum { |_k, v| v[:comments].length },
              mr_events: mrs.sum { |_k, v| v[:events].length },
              issues: gl_issues.length,
              issue_comments: gl_issues.sum { |_k, v| v[:comments].length },
              issue_events: gl_issues.sum { |_k, v| v[:events].length }
            }
          },
          not_imported: {
            mrs: @mr_diff,
            issues: @issue_diff
          }
        }))
      end

      it(
        'imports large Github repo via api',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347668'
      ) do
        if only_stats_comparison
          logger.warn("Test is running in lightweight comparison mode, only object counts will be compared!")
        end

        @start = Time.now

        # trigger import and log project paths
        logger.info("== Triggering import of project '#{github_repo}' in to '#{imported_project.reload!.full_path}' ==")

        # fetch all objects right after import has started
        fetch_github_objects unless only_stats_comparison

        import_status = -> {
          imported_project.project_import_status.yield_self do |status|
            @stats = status[:stats]&.slice(:fetched, :imported)

            # fail fast if import explicitly failed
            raise "Import of '#{imported_project.full_path}' failed!" if status[:import_status] == 'failed'

            status[:import_status]
          end
        }

        logger.info("== Waiting for import to be finished ==")
        expect(import_status).to eventually_eq('finished').within(max_duration: import_max_duration, sleep_interval: 30)

        @import_time = Time.now - @start

        if only_stats_comparison
          expect(@stats[:fetched]).to eq(@stats[:imported])
        else
          aggregate_failures do
            verify_repository_import
            verify_labels_import
            verify_milestones_import
            verify_merge_requests_import
            verify_issues_import
          end
        end
      end

      # Base test result data used for test result reporting
      #
      # @param [Hash] additional_data
      # @return [Hash]
      def test_result_data(additional_data = {})
        {
          importer: :github,
          source: {
            name: "GitHub",
            project_name: github_repo,
            address: "https://github.com"
          },
          target: {
            name: "GitLab",
            address: gitlab_address
          }
        }.deep_merge(additional_data)
      end

      # Persist all objects from repository being imported
      #
      # @return [void]
      def fetch_github_objects
        logger.info("== Fetching github repo objects ==")

        gh_repo
        gh_branches
        gh_commits
        gh_labels
        gh_milestones
        gh_issues
        gh_prs
      end

      # Verify repository imported correctly
      #
      # @return [void]
      def verify_repository_import
        logger.info("== Verifying repository import ==")
        expect(imported_project.description).to eq(gh_repo.description)
        # check via include, importer creates more branches
        # https://gitlab.com/gitlab-org/gitlab/-/issues/332711
        expect(gl_branches).to include(*gh_branches)
        expect(gl_commits).to match_array(gh_commits)
      end

      # Verify imported labels
      #
      # @return [void]
      def verify_labels_import
        logger.info("== Verifying label import ==")
        # check via include, additional labels can be inherited from parent group
        expect(gl_labels).to include(*gh_labels)
      end

      # Verify milestones import
      #
      # @return [void]
      def verify_milestones_import
        logger.info("== Verifying milestones import ==")
        expect(gl_milestones).to match_array(gh_milestones)
      end

      # Verify imported merge requests and mr issues
      #
      # @return [void]
      def verify_merge_requests_import
        logger.info("== Verifying merge request import ==")
        @mr_diff = verify_mrs_or_issues('mr')
      end

      # Verify imported issues and issue comments
      #
      # @return [void]
      def verify_issues_import
        logger.info("== Verifying issue import ==")
        @issue_diff = verify_mrs_or_issues('issue')
      end

      # This has no real effect, mostly used to group the methods that are used directly from spec body and helpers
      #
      private

      # Fetch github events and add to issue object
      #
      # @param [Hash] issuables
      # @param [String] type
      # @return [Hash]
      def fetch_github_events(issuables, type)
        logger.info("- Fetching #{type} events -")
        issuables.to_h do |id, issuable|
          logger.debug("Fetching events for #{type} !#{id}")
          events = with_paginated_request { github_client.issue_events(github_repo, id) }
            .map { |event| event[:event] }
            .reject { |event| unsupported_events.include?(event) }

          [id, issuable.merge({ events: events })]
        end
      end

      # Verify imported mrs or issues and return missing items
      #
      # @param [String] type verification object, 'mrs' or 'issues'
      # @return [Hash]
      def verify_mrs_or_issues(type)
        # Compare length to have easy to read overview how many objects are missing
        #
        expected = type == 'mr' ? mrs : gl_issues
        actual = type == 'mr' ? gh_prs : gh_issues
        count_msg = "Expected to contain same amount of #{type}s. Gitlab: #{expected.length}, Github: #{actual.length}"
        expect(expected.length).to eq(actual.length), count_msg

        missing_objects = (actual.keys - expected.keys).map { |it| actual[it].slice(:title, :url) }
        missing_content = verify_comments_and_events(type, actual, expected)

        {
          "#{type}s": missing_objects.empty? ? nil : missing_objects,
          "#{type}_content": missing_content.empty? ? nil : missing_content
        }.compact
      end

      # Verify imported comments and events
      #
      # @param [String] type verification object, 'mrs' or 'issues'
      # @param [Hash] actual
      # @param [Hash] expected
      # @return [Hash]
      def verify_comments_and_events(type, actual, expected)
        actual.each_with_object([]) do |(key, actual_item), missing_content|
          expected_item = expected[key]
          title = actual_item[:title]
          msg = "expected #{type} with iid '#{key}' to have"

          # Print title in the error message to see which object is missing
          #
          expect(expected_item).to be_truthy, "#{msg} been imported"
          next unless expected_item

          # Print difference in the description
          #
          expected_body = expected_item[:body]
          actual_body = actual_item[:body]
          body_msg = <<~MSG
            #{msg} same description. diff:\n#{differ.diff(expected_body, actual_body)}
          MSG
          expect(expected_body).to eq(actual_body), body_msg

          # Print amount difference first
          #
          expected_comments = expected_item[:comments]
          actual_comments = actual_item[:comments]
          comment_count_msg = <<~MSG
            #{msg} same amount of comments. Gitlab: #{expected_comments.length}, Github: #{actual_comments.length}
          MSG
          expect(expected_comments.length).to eq(actual_comments.length), comment_count_msg
          expect(expected_comments).to match_array(actual_comments)

          expected_events = expected_item[:events]
          actual_events = actual_item[:events]
          event_count_msg = <<~MSG
            #{msg} same amount of events. Gitlab: #{expected_events.length}, Github: #{actual_events.length}
          MSG
          expect(expected_events.length).to eq(actual_events.length), event_count_msg
          expect(expected_events).to match_array(actual_events)

          # Save missing comments and events
          #
          comment_diff = actual_comments - expected_comments
          event_diff = actual_events - expected_events
          next if comment_diff.empty? && event_diff.empty?

          missing_content << {
            title: title,
            github_url: actual_item[:url],
            gitlab_url: expected_item[:url],
            missing_comments: comment_diff.empty? ? nil : comment_diff,
            missing_events: event_diff.empty? ? nil : event_diff
          }.compact
        end
      end

      # Imported project branches
      #
      # @return [Array]
      def gl_branches
        @gl_branches ||= begin
          logger.debug("= Fetching branches =")
          imported_project.repository_branches(auto_paginate: true).map { |b| b[:name] }
        end
      end

      # Imported project commits
      #
      # @return [Array]
      def gl_commits
        @gl_commits ||= begin
          logger.debug("= Fetching commits =")
          imported_project.commits(auto_paginate: true, attempts: 2).map { |c| c[:id] }
        end
      end

      # Imported project labels
      #
      # @return [Array]
      def gl_labels
        @gl_labels ||= begin
          logger.debug("= Fetching labels =")
          imported_project.labels(auto_paginate: true).map { |label| label.slice(:name, :color) }
        end
      end

      # Imported project milestones
      #
      # @return [<Type>] <description>
      def gl_milestones
        @gl_milestones ||= begin
          logger.debug("= Fetching milestones =")
          imported_project.milestones(auto_paginate: true).map { |ms| ms.slice(:title, :description) }
        end
      end

      # Imported project merge requests
      #
      # @return [Hash]
      def mrs
        @mrs ||= begin
          logger.debug("= Fetching merge requests =")
          imported_mrs = imported_project.merge_requests(**api_request_params)

          logger.debug("- Fetching merge request comments #{api_parallel_threads} parallel threads -")
          Parallel.map(imported_mrs, in_threads: api_parallel_threads) do |mr|
            resource = Resource::MergeRequest.init do |resource|
              resource.project = imported_project
              resource.iid = mr[:iid]
              resource.api_client = api_client
            end

            comments = resource.comments(**api_request_params)
            label_events = resource.label_events(**api_request_params)
            state_events = resource.state_events(**api_request_params)
            milestone_events = resource.milestone_events(**api_request_params)

            [mr[:iid], {
              url: mr[:web_url],
              title: mr[:title],
              body: sanitize_description(mr[:description]) || '',
              events: events(comments, label_events, state_events, milestone_events),
              comments: non_event_comments(comments)
            }]
          end.to_h
        end
      end

      # Imported project issues
      #
      # @return [Hash]
      def gl_issues
        @gl_issues ||= begin
          logger.debug("= Fetching issues =")
          imported_issues = imported_project.issues(**api_request_params)

          logger.debug("- Fetching issue comments #{api_parallel_threads} parallel threads -")
          Parallel.map(imported_issues, in_threads: api_parallel_threads) do |issue|
            resource = build(:issue, project: imported_project, iid: issue[:iid], api_client: api_client)

            comments = resource.comments(**api_request_params)
            label_events = resource.label_events(**api_request_params)
            state_events = resource.state_events(**api_request_params)
            milestone_events = resource.milestone_events(**api_request_params)

            [issue[:iid], {
              url: issue[:web_url],
              title: issue[:title],
              body: sanitize_description(issue[:description]) || '',
              events: events(comments, label_events, state_events, milestone_events),
              comments: non_event_comments(comments)
            }]
          end.to_h
        end
      end

      # Filter out event comments
      #
      # @param [Array] comments
      # @return [Array]
      def non_event_comments(comments)
        comments
          .reject { |c| c[:system] || c[:body].match?(event_pattern) }
          .map { |c| sanitize_comment(c[:body]) }
      end

      # Events
      #
      # @param [Array] comments
      # @param [Array] label_events
      # @param [Array] state_events
      # @param [Array] milestone_events
      # @return [Array]
      def events(comments, label_events, state_events, milestone_events)
        mapped_label_events = label_events.map { |event| event_mapping["label_#{event[:action]}"] }
        mapped_milestone_events = milestone_events.map { |event| event_mapping["milestone_#{event[:action]}"] }
        mapped_state_event = state_events.map { |event| event[:state] }
        mapped_comment_events = comments.map do |c|
          event_mapping[c[:body].match(event_pattern)&.named_captures&.fetch("event", nil)]
        end

        [*mapped_label_events, *mapped_milestone_events, *mapped_state_event, *mapped_comment_events].compact
      end

      # Normalize comments and make them directly comparable
      #
      # * remove created by prefixes
      # * unify suggestion format
      # * replace github and gitlab urls - some of the links to objects get transformed to gitlab entities, some don't,
      #   update all links to example.com for now
      #
      # @param [String] body
      # @return [String]
      def sanitize_comment(body)
        body
          .gsub(created_by_pattern, "")
          .gsub(suggestion_pattern, "suggestion\r")
          .gsub(gl_link_pattern, dummy_url)
          .gsub(gh_link_pattern, dummy_url)
      end

      # Remove created by prefix from descripion
      #
      # @param [String] body
      # @return [String]
      def sanitize_description(body)
        body&.gsub(created_by_pattern, "")
      end

      # Save json as file
      #
      # @param [Hash] json
      # @return [void]
      def save_data_json(json)
        File.open("tmp/github-import-data.json", "w") { |file| file.write(JSON.pretty_generate(json)) }
      end

      # Extract id number from web url of issue or pull request
      #
      # Some endpoints don't return object id as separate parameter so web url can be used as a workaround
      #
      # @param [String] url
      # @return [Integer]
      def id_from_url(url)
        url.match(%r{(?<type>issues|pull)/(?<id>\d+)})&.named_captures&.fetch("id", nil).to_i
      end

      # Custom pagination for github requests
      #
      # Default autopagination doesn't work correctly with rate limit
      #
      # @return [Array]
      def with_paginated_request(&block)
        resources = with_rate_limit(&block)

        loop do
          next_link = github_client.last_response.rels[:next]&.href
          break unless next_link

          logger.debug("Fetching resources from next page: '#{next_link}'")
          resources.concat(with_rate_limit { github_client.get(next_link) })
        end

        resources
      end

      # Handle rate limit
      #
      # @return [Array]
      def with_rate_limit
        yield
      rescue Faraday::ForbiddenError => e
        raise e unless e.response[:status] == 403

        wait = github_client.rate_limit.resets_in + 5
        logger.warn("GitHub rate api rate limit reached, resuming in '#{wait}' seconds")
        logger.debug(JSON.parse(e.response[:body])['message'])
        sleep(wait)

        retry
      end

      # Get current thread id for better logging
      #
      # @return [Integer]
      def current_thread
        Thread.current.object_id
      end
    end
  end
end
# rubocop:enable Rails/Pluck
