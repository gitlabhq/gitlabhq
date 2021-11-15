# frozen_string_literal: true

module QA
  # run only base UI validation on staging because test requires top level group creation which is problematic
  # on staging environment
  RSpec.describe 'Manage', :requires_admin, except: { subdomain: :staging } do
    describe 'Bulk project import' do
      let(:import_wait_duration) { { max_duration: 300, sleep_interval: 2 } }
      let(:admin_api_client) { Runtime::API::Client.as_admin }
      let(:user) do
        Resource::User.fabricate_via_api! do |usr|
          usr.api_client = admin_api_client
          usr.hard_delete_on_api_removal = true
        end
      end

      let(:api_client) { Runtime::API::Client.new(user: user) }

      let(:sandbox) do
        Resource::Sandbox.fabricate_via_api! do |group|
          group.api_client = admin_api_client
        end
      end

      let(:source_group) do
        Resource::Sandbox.fabricate_via_api! do |group|
          group.api_client = api_client
          group.path = "source-group-for-import-#{SecureRandom.hex(4)}"
        end
      end

      let(:source_project) do
        Resource::Project.fabricate_via_api! do |project|
          project.api_client = api_client
          project.group = source_group
          project.initialize_with_readme = true
        end
      end

      let(:imported_group) do
        Resource::BulkImportGroup.fabricate_via_api! do |group|
          group.api_client = api_client
          group.sandbox = sandbox
          group.source_group_path = source_group.path
        end
      end

      let(:imported_projects) do
        imported_group.reload!.projects
      end

      let(:project_import_failures) do
        imported_group.import_details
          .find { |entity| entity[:destination_name] == source_project.name }
          &.fetch(:failures)
      end

      before do
        Runtime::Feature.enable(:bulk_import_projects)

        sandbox.add_member(user, Resource::Members::AccessLevel::MAINTAINER)

        source_project.tap { |project| project.add_push_rules(member_check: true) } # fabricate source group and project
      end

      after do
        user.remove_via_api!
      ensure
        Runtime::Feature.disable(:bulk_import_projects)
      end

      context 'with project' do
        before do
          imported_group # trigger import
        end

        it(
          'successfully imports project',
          testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/2297'
        ) do
          expect { imported_group.import_status }.to eventually_eq('finished').within(import_wait_duration)
          expect(imported_projects.count).to eq(1), "Expected to have 1 imported project"

          aggregate_failures do
            expect(imported_projects.first).to eq(source_project)
            expect(project_import_failures).to be_empty, "Expected no errors, was: #{project_import_failures}"
          end
        end
      end

      context 'with project issues' do
        let(:source_issue) do
          Resource::Issue.fabricate_via_api! do |issue|
            issue.api_client = api_client
            issue.project = source_project
            issue.labels = %w[label_one label_two]
          end
        end

        let(:imported_issues) do
          imported_projects.first.issues
        end

        let(:imported_issue) do
          issue = imported_issues.first
          Resource::Issue.init do |resource|
            resource.api_client = api_client
            resource.project = imported_projects.first
            resource.iid = issue[:iid]
          end
        end

        before do
          source_issue # fabricate source group, project, issue
          imported_group # trigger import
        end

        it(
          'successfully imports issue',
          testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/2325'
        ) do
          expect { imported_group.import_status }.to eventually_eq('finished').within(import_wait_duration)
          expect(imported_projects.count).to eq(1), "Expected to have 1 imported project"

          aggregate_failures do
            expect(imported_issues.count).to eq(1)
            expect(imported_issue.reload!).to eq(source_issue)
            expect(project_import_failures).to be_empty, "Expected no errors, was: #{project_import_failures}"
          end
        end
      end
    end
  end
end
