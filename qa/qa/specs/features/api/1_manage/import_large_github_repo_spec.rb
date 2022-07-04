# frozen_string_literal: true

# Lifesize project import test executed from https://gitlab.com/gitlab-org/manage/import/import-metrics

# rubocop:disable Rails/Pluck
module QA
  RSpec.describe 'Manage', :github, :requires_admin, only: { job: 'large-github-import' } do
    describe 'Project import' do
      let(:logger) { Runtime::Logger.logger }
      let(:differ) { RSpec::Support::Differ.new(color: true) }

      let(:created_by_pattern) { /\*Created by: \S+\*\n\n/ }
      let(:suggestion_pattern) { /suggestion:-\d+\+\d+/ }

      let(:api_client) { Runtime::API::Client.as_admin }

      let(:user) do
        Resource::User.fabricate_via_api! do |resource|
          resource.api_client = api_client
        end
      end

      let(:github_repo) { ENV['QA_LARGE_IMPORT_REPO'] || 'rspec/rspec-core' }
      let(:import_max_duration) { ENV['QA_LARGE_IMPORT_DURATION'] ? ENV['QA_LARGE_IMPORT_DURATION'].to_i : 7200 }
      let(:github_client) do
        Octokit::Client.new(
          access_token: ENV['QA_LARGE_IMPORT_GH_TOKEN'] || Runtime::Env.github_access_token,
          auto_paginate: true
        )
      end

      let(:gh_repo) { github_client.repository(github_repo) }

      let(:gh_branches) do
        logger.debug("= Fetching branches =")
        github_client.branches(github_repo).map(&:name)
      end

      let(:gh_commits) do
        logger.debug("= Fetching commits =")
        github_client.commits(github_repo).map(&:sha)
      end

      let(:gh_labels) do
        logger.debug("= Fetching labels =")
        github_client.labels(github_repo).map { |label| { name: label.name, color: "##{label.color}" } }
      end

      let(:gh_milestones) do
        logger.debug("= Fetching milestones =")
        github_client
          .list_milestones(github_repo, state: 'all')
          .map { |ms| { title: ms.title, description: ms.description } }
      end

      let(:gh_all_issues) do
        logger.debug("= Fetching issues and prs =")
        github_client.list_issues(github_repo, state: 'all')
      end

      let(:gh_prs) do
        gh_all_issues.select(&:pull_request).each_with_object({}) do |pr, hash|
          hash[pr.number] = {
            url: pr.html_url,
            title: pr.title,
            body: pr.body || '',
            comments: [*gh_pr_comments[pr.html_url], *gh_issue_comments[pr.html_url]].compact
          }
        end
      end

      let(:gh_issues) do
        gh_all_issues.reject(&:pull_request).each_with_object({}) do |issue, hash|
          hash[issue.number] = {
            url: issue.html_url,
            title: issue.title,
            body: issue.body || '',
            comments: gh_issue_comments[issue.html_url]
          }
        end
      end

      let(:gh_issue_comments) do
        logger.debug("= Fetching issue comments =")
        github_client.issues_comments(github_repo).each_with_object(Hash.new { |h, k| h[k] = [] }) do |c, hash|
          hash[c.html_url.gsub(/\#\S+/, "")] << c.body # use base html url as key
        end
      end

      let(:gh_pr_comments) do
        logger.debug("= Fetching pr comments =")
        github_client.pull_requests_comments(github_repo).each_with_object(Hash.new { |h, k| h[k] = [] }) do |c, hash|
          hash[c.html_url.gsub(/\#\S+/, "")] << c.body # use base html url as key
        end
      end

      let(:imported_project) do
        Resource::ProjectImportedFromGithub.fabricate_via_api! do |project|
          project.add_name_uuid = false
          project.name = 'imported-project'
          project.github_personal_access_token = Runtime::Env.github_access_token
          project.github_repository_path = github_repo
          project.personal_namespace = user.username
          project.api_client = api_client
        end
      end

      # rubocop:disable RSpec/InstanceVariable
      after do |example|
        next unless defined?(@import_time)

        # save data for comparison notification creation
        save_json(
          "data",
          {
            importer: :github,
            import_time: @import_time,
            errors: imported_project.project_import_status[:failed_relations],
            reported_stats: @stats,
            source: {
              name: "GitHub",
              project_name: github_repo,
              address: "https://github.com",
              data: {
                branches: gh_branches.length,
                commits: gh_commits.length,
                labels: gh_labels.length,
                milestones: gh_milestones.length,
                mrs: gh_prs.length,
                mr_comments: gh_prs.sum { |_k, v| v[:comments].length },
                issues: gh_issues.length,
                issue_comments: gh_issues.sum { |_k, v| v[:comments].length }
              }
            },
            target: {
              name: "GitLab",
              project_name: imported_project.path_with_namespace,
              address: QA::Runtime::Scenario.gitlab_address,
              data: {
                branches: gl_branches.length,
                commits: gl_commits.length,
                labels: gl_labels.length,
                milestones: gl_milestones.length,
                mrs: mrs.length,
                mr_comments: mrs.sum { |_k, v| v[:comments].length },
                issues: gl_issues.length,
                issue_comments: gl_issues.sum { |_k, v| v[:comments].length }
              }
            },
            not_imported: {
              mrs: @mr_diff,
              issues: @issue_diff
            }
          }
        )
      end
      # rubocop:enable RSpec/InstanceVariable

      it(
        'imports large Github repo via api',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347668'
      ) do
        start = Time.now

        # import the project and log gitlab path
        logger.info("== Importing project '#{github_repo}' in to '#{imported_project.reload!.full_path}' ==")
        # fetch all objects right after import has started
        fetch_github_objects

        import_status = lambda do
          imported_project.project_import_status.yield_self do |status|
            @stats = status.dig(:stats, :imported)

            # fail fast if import explicitly failed
            raise "Import of '#{imported_project.name}' failed!" if status[:import_status] == 'failed'

            status[:import_status]
          end
        end

        logger.info("== Waiting for import to be finished ==")
        expect(import_status).to eventually_eq('finished').within(max_duration: import_max_duration, sleep_interval: 30)

        @import_time = Time.now - start

        aggregate_failures do
          verify_repository_import
          verify_labels_import
          verify_milestones_import
          verify_merge_requests_import
          verify_issues_import
        end
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
        gh_prs
        gh_issues
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

      private

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

        missing_comments = verify_comments(type, actual, expected)

        {
          "#{type}s": (actual.keys - expected.keys).map { |it| actual[it].slice(:title, :url) },
          "#{type}_comments": missing_comments
        }
      end

      # Verify imported comments
      #
      # @param [String] type verification object, 'mrs' or 'issues'
      # @param [Hash] actual
      # @param [Hash] expected
      # @return [Hash]
      def verify_comments(type, actual, expected)
        actual.each_with_object([]) do |(key, actual_item), missing_comments|
          expected_item = expected[key]
          title = actual_item[:title]
          msg = "expected #{type} with title '#{title}' to have"

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

          # Save missing comments
          #
          comment_diff = actual_comments - expected_comments
          next if comment_diff.empty?

          missing_comments << {
            title: title,
            github_url: actual_item[:url],
            gitlab_url: expected_item[:url],
            missing_comments: comment_diff
          }
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
          imported_mrs = imported_project.merge_requests(auto_paginate: true, attempts: 2)

          logger.debug("= Fetching merge request comments =")
          Parallel.map(imported_mrs, in_threads: 4) do |mr|
            resource = Resource::MergeRequest.init do |resource|
              resource.project = imported_project
              resource.iid = mr[:iid]
              resource.api_client = api_client
            end

            logger.debug("Fetching comments for mr '#{mr[:title]}'")
            [mr[:iid], {
              url: mr[:web_url],
              title: mr[:title],
              body: sanitize_description(mr[:description]) || '',
              comments: resource
                .comments(auto_paginate: true, attempts: 2)
                # remove system notes
                .reject { |c| c[:system] || c[:body].match?(/^(\*\*Review:\*\*)|(\*Merged by:).*/) }
                .map { |c| sanitize_comment(c[:body]) }
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
          imported_issues = imported_project.issues(auto_paginate: true, attempts: 2)

          logger.debug("= Fetching issue comments =")
          Parallel.map(imported_issues, in_threads: 4) do |issue|
            resource = Resource::Issue.init do |issue_resource|
              issue_resource.project = imported_project
              issue_resource.iid = issue[:iid]
              issue_resource.api_client = api_client
            end

            logger.debug("Fetching comments for issue '#{issue[:title]}'")
            [issue[:iid], {
              url: issue[:web_url],
              title: issue[:title],
              body: sanitize_description(issue[:description]) || '',
              comments: resource
                .comments(auto_paginate: true, attempts: 2)
                .map { |c| sanitize_comment(c[:body]) }
            }]
          end.to_h
        end
      end

      # Remove added prefixes and legacy diff format from comments
      #
      # @param [String] body
      # @return [String]
      def sanitize_comment(body)
        body.gsub(created_by_pattern, "").gsub(suggestion_pattern, "suggestion\r")
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
      # @param [String] name
      # @param [Hash] json
      # @return [void]
      def save_json(name, json)
        File.open("tmp/#{name}.json", "w") { |file| file.write(JSON.pretty_generate(json)) }
      end
    end
  end
end
# rubocop:enable Rails/Pluck
