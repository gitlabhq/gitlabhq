# frozen_string_literal: true

# Lifesize project import test executed from https://gitlab.com/gitlab-org/manage/import/import-metrics

# rubocop:disable Rails/Pluck, Layout/LineLength, RSpec/MultipleMemoizedHelpers
module QA
  RSpec.describe "Manage", :skip_live_env, product_group: :import_and_integrate,
    only: { condition: -> { ENV["CI_PROJECT_NAME"] == "import-metrics" } },
    custom_test_metrics: {
      tags: { import_type: ENV["QA_IMPORT_TYPE"], import_repo: ENV["QA_LARGE_IMPORT_REPO"] || "migration-test-project" }
    } do
    describe "Gitlab migration", :import, orchestrated: false, requires_admin: 'creates a user via API' do
      include_context "with gitlab group migration"

      let!(:logger) { Runtime::Logger.logger }
      let!(:differ) { RSpec::Support::Differ.new(color: true) }
      let!(:source_gitlab_address) { ENV["QA_LARGE_IMPORT_SOURCE_URL"] || "https://gitlab.com" }
      let!(:gitlab_source_group) { ENV["QA_LARGE_IMPORT_GROUP"] || "gitlab-migration-large-import-test" }
      let!(:gitlab_source_project) { ENV["QA_LARGE_IMPORT_REPO"] || "migration-test-project" }
      let!(:import_wait_duration) { { max_duration: (ENV["QA_LARGE_IMPORT_DURATION"] || 3600).to_i, sleep_interval: 30 } }
      let!(:api_parallel_threads) { ENV['QA_LARGE_IMPORT_API_PARALLEL']&.to_i || Etc.nprocessors }

      # test uses production as source which doesn't have actual admin user
      let!(:source_admin_user) { nil }
      let!(:source_admin_api_client) do
        Runtime::API::Client.new(
          source_gitlab_address,
          personal_access_token: ENV["QA_LARGE_IMPORT_GL_TOKEN"] || raise("missing QA_LARGE_IMPORT_GL_TOKEN variable")
        )
      end

      # alias api client because for large import test it's not an actual admin user
      let!(:source_api_client) { source_admin_api_client }

      let!(:source_group) do
        paths = gitlab_source_group.split("/")
        sandbox = build(:sandbox, api_client: source_api_client, path: paths.first).reload!
        next sandbox if paths.size == 1

        paths[1..].each_with_object([sandbox]) do |path, arr|
          arr << build(:group, api_client: source_api_client, sandbox: arr.last, path: path).reload!
        end.last
      end

      # generate unique target group because source group has a static name
      let!(:target_sandbox) do
        create(:sandbox, api_client: admin_api_client, path: "qa-sandbox-#{SecureRandom.hex(4)}")
      end

      let!(:api_client) do
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

      # Source objects
      #
      let(:source_project) { source_group.projects(auto_paginate: true).find { |project| project.name == gitlab_source_project }.reload! }
      let(:source_branches) { source_project.repository_branches(auto_paginate: true).map { |b| b[:name] } }
      let(:source_commits) { source_project.commits(auto_paginate: true).map { |c| c[:id] } }
      let(:source_labels) { source_project.labels(auto_paginate: true).map { |l| l.except(:id, :description_html) } }
      let(:source_milestones) { source_project.milestones(auto_paginate: true).map { |ms| ms.except(:id, :web_url, :project_id) } }
      let(:source_mrs) { fetch_mrs(source_project, source_api_client, transform_urls: true) }
      let(:source_issues) { fetch_issues(source_project, source_api_client, transform_urls: true) }
      let(:source_pipelines) do
        source_project
          .pipelines(auto_paginate: true)
          .sort_by { |pipeline| pipeline[:created_at] }
          .map do |pipeline|
            pp = pipeline.except(:id, :web_url, :project_id)
            # pending and manual pipelines are imported with status set to canceled
            next pp unless pp[:status] == "pending" || pp[:status] == "manual"

            pp.merge({ status: "canceled" })
          end
      end

      # Imported objects
      #
      let(:imported_project) { imported_group.projects(auto_paginate: true).find { |project| project.name == gitlab_source_project }.reload! }
      let(:branches) { imported_project.repository_branches(auto_paginate: true, attempts: 3).map { |b| b[:name] } }
      let(:commits) { imported_project.commits(auto_paginate: true, attempts: 3).map { |c| c[:id] } }
      let(:labels) { imported_project.labels(auto_paginate: true, attempts: 3).map { |l| l.except(:id, :description_html) } }
      let(:milestones) { imported_project.milestones(auto_paginate: true, attempts: 3).map { |ms| ms.except(:id, :web_url, :project_id) } }
      let(:mrs) { fetch_mrs(imported_project, api_client) }
      let(:issues) { fetch_issues(imported_project, api_client) }
      let(:pipelines) do
        imported_project
          .pipelines(auto_paginate: true, attempts: 3)
          .sort_by { |pipeline| pipeline[:created_at] }
          .map { |pipeline| pipeline.except(:id, :web_url, :project_id) }
      end

      before do
        QA::Support::Helpers::ImportSource.enable(%w[gitlab_project])
      end

      # rubocop:disable RSpec/InstanceVariable
      after do |example|
        unless defined?(@import_time)
          next save_json(
            {
              status: "failed",
              importer: :gitlab,
              import_finished: false,
              import_time: Time.now - @start,
              source: {
                name: "GitLab Source",
                project_name: source_project.path_with_namespace,
                address: source_gitlab_address
              },
              target: {
                name: "GitLab Target",
                address: QA::Runtime::Scenario.gitlab_address
              }
            }
          )
        end

        # add additional import time metric
        example.metadata[:custom_test_metrics][:fields] = { import_time: @import_time }
        # save data for comparison notification creation
        save_json(
          {
            status: example.exception ? "failed" : "passed",
            importer: :gitlab,
            import_time: @import_time,
            import_finished: true,
            errors: import_failures,
            source: {
              name: "GitLab Source",
              project_name: source_project.path_with_namespace,
              address: source_gitlab_address,
              data: {
                branches: source_branches.length,
                commits: source_commits.length,
                labels: source_labels.length,
                milestones: source_milestones.length,
                pipelines: source_pipelines.length,
                mrs: source_mrs.length,
                mr_comments: source_mrs.sum { |_k, v| v[:comments].length },
                issues: source_issues.length,
                issue_comments: source_issues.sum { |_k, v| v[:comments].length }
              }
            },
            target: {
              name: "GitLab Target",
              project_name: imported_project.path_with_namespace,
              address: QA::Runtime::Scenario.gitlab_address,
              data: {
                branches: branches.length,
                commits: commits.length,
                labels: labels.length,
                milestones: milestones.length,
                pipelines: pipelines.length,
                mrs: mrs.length,
                mr_comments: mrs.sum { |_k, v| v[:comments].length },
                issues: issues.length,
                issue_comments: issues.sum { |_k, v| v[:comments].length }
              }
            },
            diff: {
              mrs: @mr_diff,
              issues: @issue_diff
            }
          }
        )
      end

      it "migrates large gitlab group via api", testcase: "https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/358842" do
        @start = Time.now

        # trigger import and log imported group path
        logger.info("== Importing group '#{gitlab_source_group}' in to '#{imported_group.full_path}' ==")

        # fetch all objects right after import has started
        fetch_source_gitlab_objects

        # wait for import to finish and save import time
        logger.info("== Waiting for import to be finished ==")
        expect_group_import_finished_successfully

        @import_time = Time.now - @start

        aggregate_failures do
          verify_repository_import
          verify_labels_import
          verify_milestones_import
          verify_pipelines_import
          verify_merge_requests_import
          verify_issues_import
        end
      end
      # rubocop:enable RSpec/InstanceVariable

      # Fetch source project objects for comparison
      #
      # @return [void]
      def fetch_source_gitlab_objects
        logger.info("== Fetching source group objects ==")

        source_branches
        source_commits
        source_labels
        source_milestones
        source_pipelines
        source_mrs
        source_issues
      end

      # Verify repository imported correctly
      #
      # @return [void]
      def verify_repository_import
        logger.info("== Verifying repository import ==")
        expect(imported_project.description).to eq(source_project.description)
        expect(branches).to match_array(source_branches)
        expect(commits).to match_array(source_commits)
      end

      # Verify imported labels
      #
      # @return [void]
      def verify_labels_import
        logger.info("== Verifying label import ==")
        expect(labels).to include(*source_labels)
      end

      # Verify milestones import
      #
      # @return [void]
      def verify_milestones_import
        logger.info("== Verifying milestones import ==")
        expect(milestones).to match_array(source_milestones)
      end

      # Verify pipelines import
      #
      # @return [void]
      def verify_pipelines_import
        logger.info("== Verifying pipelines import ==")
        expect(pipelines).to eq(source_pipelines)
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

      # Verify imported mrs or issues and return missing items
      #
      # @param [String] type verification object, 'mr' or 'issue'
      # @return [Hash]
      def verify_mrs_or_issues(type)
        # Compare length to have easy to read overview how many objects are missing
        #
        expected = type == 'mr' ? source_mrs : source_issues
        actual = type == 'mr' ? mrs : issues
        count_msg = "Expected to contain same amount of #{type}s. Source: #{expected.length}, Target: #{actual.length}"
        expect(actual.length).to eq(expected.length), count_msg

        comment_diff = verify_comments(type, actual, expected)

        {
          "missing_#{type}s": (expected.keys - actual.keys).filter_map { |it| expected[it]&.slice(:title, :url) },
          "extra_#{type}s": (actual.keys - expected.keys).filter_map { |it| actual[it]&.slice(:title, :url) },
          "#{type}_comments": comment_diff
        }
      end

      # Verify imported comments
      #
      # @param [String] type verification object, 'mrs' or 'issues'
      # @param [Hash] actual
      # @param [Hash] expected
      # @return [Hash]
      def verify_comments(type, actual, expected)
        actual.each_with_object([]) do |(key, actual_item), diff|
          expected_item = expected[key]
          title = actual_item[:title]
          msg = "expected #{type} with title '#{title}' to have"

          # Print title in the error message to see which object is missing
          #
          expect(actual_item).to be_truthy, "#{msg} been imported"
          next unless expected_item

          # Print difference in the description
          #
          expected_body = remove_backticks(expected_item[:body])
          actual_body = remove_backticks(actual_item[:body])
          body_msg = "#{msg} same description. diff:\n#{differ.diff(expected_body, actual_body)}"
          expect(actual_body).to eq(expected_body), body_msg

          # Print difference in state
          #
          expected_state = expected_item[:state]
          actual_state = actual_item[:state]
          state_msg = "#{msg} same state. Source: #{expected_state}, Target: #{actual_state}"
          expect(actual_state).to eq(expected_state), state_msg

          # Print amount difference first
          #
          expected_comments = expected_item[:comments].map { |comment| remove_backticks(comment) }
          actual_comments = actual_item[:comments].map { |comment| remove_backticks(comment) }
          comment_count_msg = <<~MSG
            #{msg} same amount of comments. Source: #{expected_comments.length}, Target: #{actual_comments.length}
          MSG
          expect(actual_comments.length).to eq(expected_comments.length), comment_count_msg
          expect(actual_comments).to match_array(expected_comments)

          # Save comment diff
          #
          missing_comments = expected_comments - actual_comments
          extra_comments = actual_comments - expected_comments
          next if missing_comments.empty? && extra_comments.empty?

          diff << {
            title: title,
            target_url: actual_item[:url],
            source_url: expected_item[:url],
            missing_comments: missing_comments,
            extra_comments: extra_comments
          }
        end
      end

      private

      # Project merge requests with comments
      #
      # @param [QA::Resource::Project]
      # @param [Runtime::API::Client] client
      # @param [Boolean] transform_urls
      # @return [Hash]
      def fetch_mrs(project, client, transform_urls: false)
        imported_mrs = project.merge_requests(auto_paginate: true, attempts: 3)

        Parallel.map(imported_mrs, in_threads: api_parallel_threads) do |mr|
          resource = build(:merge_request, project: project, iid: mr[:iid], api_client: client)

          [mr[:iid], {
            url: mr[:web_url],
            title: mr[:title],
            body: sanitize_description(mr[:description], transform_urls) || '',
            state: mr[:state],
            comments: resource
              .comments(auto_paginate: true, attempts: 3)
              .map { |c| sanitize_comment(c[:body], transform_urls) }
          }]
        end.to_h
      end

      # Project issues with comments
      #
      # @param [QA::Resource::Project]
      # @param [Runtime::API::Client] client
      # @param [Boolean] transform_urls
      # @return [Hash]
      def fetch_issues(project, client, transform_urls: false)
        imported_issues = project.issues(auto_paginate: true, attempts: 3)

        Parallel.map(imported_issues, in_threads: api_parallel_threads) do |issue|
          resource = build(:issue, project: project, iid: issue[:iid], api_client: client)

          [issue[:iid], {
            url: issue[:web_url],
            title: issue[:title],
            state: issue[:state],
            body: sanitize_description(issue[:description], transform_urls) || '',
            comments: resource
              .comments(auto_paginate: true, attempts: 3)
              .map { |c| sanitize_comment(c[:body], transform_urls) }
          }]
        end.to_h
      end

      # Remove added postfixes and transform urls
      #
      # Source urls need to be replaced with target urls for comparison to work
      #
      # @param [String] body
      # @param [Boolean] transform_urls
      # @return [String]
      def sanitize_comment(body, transform_urls)
        comment = body&.gsub(created_by_pattern, "")
        return comment unless transform_urls

        comment&.gsub(source_project_url, imported_project_url)
      end

      # Remove added postfixes and transform urls
      #
      # Source urls need to be replaced with target urls for comparison to work
      #
      # @param [String] body
      # @param [Boolean] transform_urls
      # @return [String]
      def sanitize_description(body, transform_urls)
        description = body&.gsub(created_by_pattern, "")
        return description unless transform_urls

        description&.gsub(source_project_url, imported_project_url)
      end

      # Following objects are memoized via instance variables due to Parallel having some type of issue calling
      # helpers defined via rspec let method

      # Importer user mention pattern
      #
      # @return [Regex]
      def created_by_pattern
        @created_by_pattern ||= /\n\n \*By .+ on \S+\*/
      end

      # Remove backticks from string
      #
      # @param [String] text
      # @return [String] modified text
      def remove_backticks(text)
        return unless text.present?

        text.delete('`')
      end

      # Source project url
      #
      # @return [String]
      def source_project_url
        @source_group_url ||= "#{source_gitlab_address}/#{source_project.full_path}"
      end

      # Imported project url
      #
      # This needs to be constructed manually because it is called before project import finishes
      #
      # @return [String]
      def imported_project_url
        @imported_group_url ||= "#{Runtime::Scenario.gitlab_address}/#{imported_group.full_path}/#{source_project.path}"
      end

      # Save json as file
      #
      # @param [Hash] json
      # @return [void]
      def save_json(json)
        File.open("tmp/gitlab-import-data.json", "w") { |file| file.write(JSON.pretty_generate(json)) }
      end
    end
  end
end
# rubocop:enable Rails/Pluck, Layout/LineLength, RSpec/MultipleMemoizedHelpers
