# frozen_string_literal: true

# Lifesize project import test executed from https://gitlab.com/gitlab-org/manage/import/import-metrics

# rubocop:disable Rails/Pluck, Layout/LineLength, RSpec/MultipleMemoizedHelpers
module QA
  RSpec.describe "Manage", requires_admin: 'uses admin API client for resource creation',
                           feature_flag: { name: 'bulk_import_projects', scope: :global },
                           only: { job: 'large-gitlab-import' } do
    describe "Gitlab migration" do
      let(:logger) { Runtime::Logger.logger }
      let(:differ) { RSpec::Support::Differ.new(color: true) }
      let(:gitlab_group) { ENV['QA_LARGE_IMPORT_GROUP'] || 'gitlab-migration' }
      let(:gitlab_project) { ENV['QA_LARGE_IMPORT_REPO'] || 'dri' }
      let(:gitlab_source_address) { ENV['QA_LARGE_IMPORT_SOURCE_URL'] || 'https://staging.gitlab.com' }

      let(:import_wait_duration) do
        {
          max_duration: (ENV['QA_LARGE_IMPORT_DURATION'] || 3600).to_i,
          sleep_interval: 30
        }
      end

      let(:admin_api_client) { Runtime::API::Client.as_admin }

      # explicitly create PAT via api to not create it via UI in environments where admin token env var is not present
      let(:target_api_client) do
        Runtime::API::Client.new(
          user: user,
          personal_access_token: Resource::PersonalAccessToken.fabricate_via_api! do |pat|
            pat.api_client = admin_api_client
          end.token
        )
      end

      let(:user) do
        Resource::User.fabricate_via_api! do |usr|
          usr.api_client = admin_api_client
        end
      end

      let(:source_api_client) do
        Runtime::API::Client.new(
          gitlab_source_address,
          personal_access_token: ENV["QA_LARGE_IMPORT_GL_TOKEN"],
          is_new_session: false
        )
      end

      let(:sandbox) do
        Resource::Sandbox.fabricate_via_api! do |group|
          group.api_client = admin_api_client
        end
      end

      let(:destination_group) do
        Resource::Group.fabricate_via_api! do |group|
          group.api_client = admin_api_client
          group.sandbox = sandbox
          group.path = "imported-group-destination-#{SecureRandom.hex(4)}"
        end
      end

      # Source group and it's objects
      #
      let(:source_group) do
        Resource::Sandbox.fabricate_via_api! do |group|
          group.api_client = source_api_client
          group.path = gitlab_group
        end
      end

      let(:source_project) { source_group.projects.find { |project| project.name.include?(gitlab_project) }.reload! }
      let(:source_branches) { source_project.repository_branches(auto_paginate: true).map { |b| b[:name] } }
      let(:source_commits) { source_project.commits(auto_paginate: true).map { |c| c[:id] } }
      let(:source_labels) { source_project.labels(auto_paginate: true).map { |l| l.except(:id) } }
      let(:source_milestones) { source_project.milestones(auto_paginate: true).map { |ms| ms.except(:id, :web_url, :project_id) } }
      let(:source_pipelines) { source_project.pipelines(auto_paginate: true).map { |pp| pp.except(:id, :web_url, :project_id) } }
      let(:source_mrs) { fetch_mrs(source_project, source_api_client) }
      let(:source_issues) { fetch_issues(source_project, source_api_client) }

      # Imported group and it's objects
      #
      let(:imported_group) do
        Resource::BulkImportGroup.fabricate_via_api! do |group|
          group.import_access_token = source_api_client.personal_access_token # token for importing on source instance
          group.api_client = target_api_client # token used by qa framework to access resources in destination instance
          group.gitlab_address = gitlab_source_address
          group.source_group = source_group
          group.sandbox = destination_group
        end
      end

      let(:imported_project) { imported_group.projects.find { |project| project.name.include?(gitlab_project) }.reload! }
      let(:branches) { imported_project.repository_branches(auto_paginate: true).map { |b| b[:name] } }
      let(:commits) { imported_project.commits(auto_paginate: true).map { |c| c[:id] } }
      let(:labels) { imported_project.labels(auto_paginate: true).map { |l| l.except(:id) } }
      let(:milestones) { imported_project.milestones(auto_paginate: true).map { |ms| ms.except(:id, :web_url, :project_id) } }
      let(:pipelines) { imported_project.pipelines.map { |pp| pp.except(:id, :web_url, :project_id) } }
      let(:mrs) { fetch_mrs(imported_project, target_api_client) }
      let(:issues) { fetch_issues(imported_project, target_api_client) }

      before do
        Runtime::Feature.enable(:bulk_import_projects)

        destination_group.add_member(user, Resource::Members::AccessLevel::MAINTAINER)
      end

      # rubocop:disable RSpec/InstanceVariable
      after do |example|
        next unless defined?(@import_time)

        # save data for comparison notification creation
        save_json(
          "data",
          {
            importer: :gitlab,
            import_time: @import_time,
            errors: imported_group.import_details.sum([]) { |details| details[:failures] },
            source: {
              name: "GitLab Source",
              project_name: source_project.path_with_namespace,
              address: gitlab_source_address,
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
      # rubocop:enable RSpec/InstanceVariable

      it "migrates large gitlab group via api", testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/358842' do
        start = Time.now

        # trigger import and log imported group path
        logger.info("== Importing group '#{gitlab_group}' in to '#{imported_group.full_path}' ==")

        # fetch all objects right after import has started
        fetch_source_gitlab_objects

        # wait for import to finish and save import time
        logger.info("== Waiting for import to be finished ==")
        expect { imported_group.import_status }.to eventually_eq('finished').within(import_wait_duration)
        @import_time = Time.now - start

        aggregate_failures do
          verify_repository_import
          verify_labels_import
          verify_milestones_import
          verify_pipelines_import
          verify_merge_requests_import
          verify_issues_import
        end
      end

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
        expect(pipelines).to match_array(source_pipelines)
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
          "missing_#{type}s": (expected.keys - actual.keys).map { |it| actual[it]&.slice(:title, :url) }.compact,
          "extra_#{type}s": (actual.keys - expected.keys).map { |it| expected[it]&.slice(:title, :url) }.compact,
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
          expected_body = expected_item[:body]
          actual_body = actual_item[:body]
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
          expected_comments = expected_item[:comments]
          actual_comments = actual_item[:comments]
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
      # @return [Hash]
      def fetch_mrs(project, client)
        imported_mrs = project.merge_requests(auto_paginate: true, attempts: 2)

        Parallel.map(imported_mrs, in_threads: 4) do |mr|
          resource = Resource::MergeRequest.init do |resource|
            resource.project = project
            resource.iid = mr[:iid]
            resource.api_client = client
          end

          [mr[:iid], {
            url: mr[:web_url],
            title: mr[:title],
            body: sanitize_description(mr[:description]) || '',
            state: mr[:state],
            comments: resource
              .comments(auto_paginate: true, attempts: 2)
              .map { |c| sanitize_comment(c[:body]) }
          }]
        end.to_h
      end

      # Project issues with comments
      #
      # @param [QA::Resource::Project]
      # @param [Runtime::API::Client] client
      # @return [Hash]
      def fetch_issues(project, client)
        imported_issues = project.issues(auto_paginate: true, attempts: 2)

        Parallel.map(imported_issues, in_threads: 4) do |issue|
          resource = Resource::Issue.init do |issue_resource|
            issue_resource.project = project
            issue_resource.iid = issue[:iid]
            issue_resource.api_client = client
          end

          [issue[:iid], {
            url: issue[:web_url],
            title: issue[:title],
            state: issue[:state],
            body: sanitize_description(issue[:description]) || '',
            comments: resource
              .comments(auto_paginate: true, attempts: 2)
              .map { |c| sanitize_comment(c[:body]) }
          }]
        end.to_h
      end

      # Importer user mention pattern
      #
      # @return [Regex]
      def created_by_pattern
        @created_by_pattern ||= /\n\n \*By #{importer_username_pattern} on \S+ \(imported from GitLab\)\*/
      end

      # Username of importer user for removal from comments and descriptions
      #
      # @return [String]
      def importer_username_pattern
        @importer_username_pattern ||= ENV['QA_LARGE_IMPORT_USER_PATTERN'] || "(gitlab-migration|GitLab QA Bot)"
      end

      # Remove added prefixes from comments
      #
      # @param [String] body
      # @return [String]
      def sanitize_comment(body)
        body&.gsub(created_by_pattern, "")
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
# rubocop:enable Rails/Pluck, Layout/LineLength, RSpec/MultipleMemoizedHelpers
