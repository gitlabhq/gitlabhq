# frozen_string_literal: true

require "etc"

# Lifesize project import test executed from https://gitlab.com/gitlab-org/manage/import/import-metrics
#
# This test is executed using different size live projects on GitHub.
# Due to projects being active, there can be a lag between when test is fetching data from GitHub and
#   when importer is fetching data. It can create extra objects in imported project compared to test expectation.
# Because of this, all expectation check for inclusion rather than exact match to avoid failures if extra issues,
#   comments, events got created while import was running.

# rubocop:disable Rails/Pluck -- false positive matches
# rubocop:disable RSpec/MultipleMemoizedHelpers -- slightly specific test which relies on instance variables to track metrics
module QA
  RSpec.describe 'Manage', :github, requires_admin: 'creates users',
    only: { condition: -> { ENV["CI_PROJECT_NAME"] == "import-metrics" } },
    custom_test_metrics: {
      tags: { import_type: ENV["QA_IMPORT_TYPE"], import_repo: ENV["QA_LARGE_IMPORT_REPO"] || "rspec/rspec-core" }
    } do
    describe 'Project import', product_group: :import_and_integrate do
      let!(:api_client) { Runtime::API::Client.as_admin }
      let!(:user) { create(:user) }
      let!(:user_api_client) do
        Runtime::API::Client.new(
          # importing very large project can take multiple days
          # token must not expire while we still poll for import result
          personal_access_token: create(
            :personal_access_token,
            user_id: user.id,
            expires_at: (Time.now.to_date + 6)
          ).token
        )
      end

      # Full object comparison is a fairly heavy operation
      # Importer itself returns counts of objects it fetched and counts it imported
      # We can use that for a lightweight comparison for very large projects
      let(:only_stats_comparison) { ENV["QA_LARGE_IMPORT_GH_ONLY_STATS_COMPARISON"] == "true" }
      let(:github_repo) { ENV['QA_LARGE_IMPORT_REPO'] || 'rspec/rspec-core' }
      let(:import_max_duration) { ENV['QA_LARGE_IMPORT_DURATION']&.to_i || 7200 }
      let(:api_parallel_threads) { ENV['QA_LARGE_IMPORT_API_PARALLEL']&.to_i || Etc.nprocessors }

      let(:logger) { Runtime::Logger.logger }
      let(:gitlab_address) { QA::Runtime::Scenario.gitlab_address.chomp("/") }
      let(:dummy_url) { "https://example.com" } # this is used to replace all dynamic urls in descriptions and comments
      let(:api_request_params) { { auto_paginate: true, attempts: 3 } }

      let(:created_by_pattern) { /\*Created by: \S+\*\n\n/ }
      let(:suggestion_pattern) { /suggestion:-\d+\+\d+/ }
      let(:gh_link_pattern) { %r{https://github.com/#{github_repo}/(issues|pull)} }
      let(:gl_link_pattern) { %r{#{gitlab_address}/#{imported_project.path_with_namespace}/-/(issues|merge_requests)} }
      # rubocop:disable Lint/MixedRegexpCaptureTypes -- optional capture groups
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

      let(:github_client) do
        Octokit::Client.new(
          access_token: ENV['QA_LARGE_IMPORT_GH_TOKEN'] || Runtime::Env.github_access_token,
          per_page: 100,
          middleware: Faraday::RackBuilder.new do |builder|
            builder.use(Faraday::Retry::Middleware,
              max: 3,
              interval: 1,
              retry_block: ->(exception:, **) { logger.warn("Request to GitHub failed: '#{exception}', retrying") },
              exceptions: [Faraday::ServerError, Faraday::ConnectionFailed, Faraday::SSLError]
            )
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

      let(:gh_milestone_titles) do
        gh_milestones.map { |milestone| milestone[:title] }
      end

      let(:gh_all_issues) do
        logger.info("= Fetching issues and prs =")
        with_paginated_request { github_client.list_issues(github_repo, state: 'all') }
      end

      let(:gh_issues) do
        gh_all_issues.reject(&:pull_request).each_with_object({}) do |issue, hash|
          id = issue.number
          logger.debug("- Fetching comments and events for issue #{id} -")
          hash[id] = {
            url: issue.html_url,
            title: issue.title,
            body: issue.body || '',
            comments: fetch_issuable_comments(id, "issue"),
            events: fetch_issuable_events(id)
          }
        end
      end

      let(:gh_prs) do
        gh_all_issues.select(&:pull_request).each_with_object({}) do |pr, hash|
          id = pr.number
          logger.debug("- Fetching comments and events for pr #{id} -")
          hash[id] = {
            url: pr.html_url,
            title: pr.title,
            body: pr.body || '',
            comments: fetch_issuable_comments(id, "pr"),
            events: fetch_issuable_events(id)
          }
        end
      end

      let(:imported_project) do
        Resource::ProjectImportedFromGithub.fabricate_via_api! do |project|
          project.add_name_uuid = false
          project.name = 'imported-project'
          project.github_personal_access_token = Runtime::Env.github_access_token
          project.github_repository_path = github_repo
          project.personal_namespace = user.username
          project.api_client = user_api_client
          project.full_notes_import = true
        end
      end

      let(:status_details) { (@import_status || {}).slice(:import_error, :failed_relations, :correlation_id) }

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
          }.merge(status_details)))
        end

        # add additional import time metric
        example.metadata[:custom_test_metrics][:fields] = { import_time: @import_time }
        # save data for comparison notification creation
        if only_stats_comparison
          next save_data_json(test_result_data({
            status: example.exception ? "failed" : "passed",
            import_time: @import_time,
            import_finished: true,
            reported_stats: @stats
          }.merge(status_details)))
        end

        save_data_json(test_result_data({
          status: example.exception ? "failed" : "passed",
          import_time: @import_time,
          import_finished: true,
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
          diff: {
            mrs: @mr_diff,
            issues: @issue_diff
          }
        }.merge(status_details)))
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
          @import_status = Support::Retrier.retry_on_exception(
            sleep_interval: 1,
            log: false,
            message: "Fetching import status"
          ) do
            imported_project.project_import_status
          end
          @stats = @import_status[:stats]&.slice(:fetched, :imported)
          # fail fast if import explicitly failed
          raise "Import of '#{imported_project.full_path}' failed!" if @import_status[:import_status] == 'failed'

          @import_status[:import_status]
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
            address: gitlab_address,
            project_name: imported_project.full_path
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
        expect(gl_branches).to include(*gh_branches)

        # When testing with very large repositories, comparing with include will raise 'stack level too deep' error
        # Compare just the size in this case
        if gh_commits.size > 10000
          expect(gl_commits.size).to be >= gh_commits.size
        else
          expect(gl_commits).to include(*gh_commits)
        end
      end

      # Verify imported labels
      #
      # @return [void]
      def verify_labels_import
        logger.info("== Verifying label import ==")
        expect(gl_labels).to include(*gh_labels)
      end

      # Verify milestones import
      #
      # @return [void]
      def verify_milestones_import
        logger.info("== Verifying milestones import ==")
        expect(gl_milestones).to include(*gh_milestones)
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

      # Fetch issuable object comments
      #
      # @param [Integer] id
      # @param [String] type
      # @return [Array]
      def fetch_issuable_comments(id, type)
        pr = type == "pr"
        comments = []
        # every pr is also an issue, so when fetching pr comments, issue endpoint has to be used as well
        comments.push(*with_paginated_request { github_client.issue_comments(github_repo, id) })
        comments.push(*with_paginated_request { github_client.pull_request_comments(github_repo, id) }) if pr
        comments.map! { |comment| comment.body&.gsub(gh_link_pattern, dummy_url) }
        return comments unless pr

        # some suggestions can contain extra whitespaces which gitlab will remove
        comments.map { |comment| comment.gsub(/suggestion\s+\r/, "suggestion\r") }
      end

      # Fetch issuable object events
      #
      # @param [Integer] id
      # @return [Array]
      def fetch_issuable_events(id)
        with_paginated_request { github_client.issue_events(github_repo, id) }
          .reject { |event| deleted_milestone_event?(event) }
          .map { |event| event[:event] }
          .reject { |event| unsupported_events.include?(event) }
      end

      # Verify imported mrs or issues and return content diff
      #
      # @param [String] type verification object, 'mrs' or 'issues'
      # @return [Hash]
      def verify_mrs_or_issues(type)
        # Compare length to have easy to read overview how many objects are missing
        #
        expected = type == 'mr' ? gh_prs : gh_issues
        actual = type == 'mr' ? mrs : gl_issues

        missing_objects = (expected.keys - actual.keys).map { |it| expected[it].slice(:title, :url) }
        extra_objects = (actual.keys - expected.keys).map { |it| actual[it].slice(:title, :url) }
        count_msg = <<~MSG
          Expected to contain all of GitHub's #{type}s. Gitlab: #{actual.length}, Github: #{expected.length}.
          Missing: #{missing_objects.map { |it| it[:url] }}
        MSG
        expect(expected.length <= actual.length).to be_truthy, count_msg

        content_diff = verify_comments_and_events(type, actual, expected)

        {
          "extra_#{type}s": extra_objects,
          "missing_#{type}s": missing_objects,
          "#{type}_content_diff": content_diff
        }.compact_blank
      end

      # Verify imported comments and events
      #
      # @param [String] type verification object, 'mrs' or 'issues'
      # @param [Hash] actual
      # @param [Hash] expected
      # @return [Hash]
      def verify_comments_and_events(type, actual, expected)
        actual.each_with_object([]) do |(key, actual_item), content_diff|
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
          body_msg = "#{msg} same description"
          expect(expected_body).to eq(actual_body), body_msg

          # Print amount difference first
          #
          expected_comments = expected_item[:comments]
          actual_comments = actual_item[:comments]
          comment_count_msg = <<~MSG.strip
            #{msg} same comments. GitHub: #{expected_comments.length}, GitLab: #{actual_comments.length}
          MSG
          expect(actual_comments).to include(*expected_comments), comment_count_msg

          expected_events = expected_item[:events]
          actual_events = actual_item[:events]
          event_count_msg = <<~MSG.strip
            #{msg} same events. GitHub: #{expected_events.length}, GitLab: #{actual_events.length}.
            Missing event: #{expected_events - actual_events}
          MSG
          expect(actual_events).to include(*expected_events), event_count_msg

          # Save comment and event diff
          #
          missing_comments = expected_comments - actual_comments
          extra_comments = actual_comments - expected_comments
          missing_events = expected_events - actual_events
          extra_events = actual_events - expected_events
          next if [missing_comments, missing_events, extra_comments, extra_events].all?(&:empty?)

          content_diff << {
            title: title,
            github_url: expected_item[:url],
            gitlab_url: actual_item[:url],
            missing_comments: missing_comments,
            extra_comments: extra_comments,
            missing_events: missing_events,
            extra_events: extra_events
          }.compact_blank
        end
      end

      # Imported project branches
      #
      # @return [Array]
      def gl_branches
        @gl_branches ||= begin
          logger.debug("= Fetching branches =")
          imported_project.repository_branches(auto_paginate: true, attempts: 3).map { |b| b[:name] }
        end
      end

      # Imported project commits
      #
      # @return [Array]
      def gl_commits
        @gl_commits ||= begin
          logger.debug("= Fetching commits =")
          imported_project.commits(auto_paginate: true, attempts: 3).map { |c| c[:id] }
        end
      end

      # Imported project labels
      #
      # @return [Array]
      def gl_labels
        @gl_labels ||= begin
          logger.debug("= Fetching labels =")
          imported_project.labels(auto_paginate: true, attempts: 3).map { |label| label.slice(:name, :color) }
        end
      end

      # Imported project milestones
      #
      # @return [<Type>] <description>
      def gl_milestones
        @gl_milestones ||= begin
          logger.debug("= Fetching milestones =")
          imported_project.milestones(auto_paginate: true, attempts: 3).map { |ms| ms.slice(:title, :description) }
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
            resource = build(:merge_request, project: imported_project, iid: mr[:iid], api_client: api_client)

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
        # merged events are fetched through comments so duplicates need to be removed
        mapped_state_event = state_events.map { |event| event[:state] }.reject { |state| state == "merged" }
        mapped_comment_events = comments.map do |c|
          event_mapping[c[:body].match(event_pattern)&.named_captures&.fetch("event", nil)]
        end

        [*mapped_label_events, *mapped_milestone_events, *mapped_state_event, *mapped_comment_events].compact
      end

      # Check if a milestone event is from a deleted milestone
      #
      # @param [Hash] event
      # @return [Boolean]
      def deleted_milestone_event?(event)
        return false if %w[milestoned demilestoned].exclude?(event[:event])

        gh_milestone_titles.exclude?(event[:milestone][:title])
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
# rubocop:enable RSpec/MultipleMemoizedHelpers
