# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', :requires_admin do
    describe 'Bulk project import' do
      let!(:staging?) { Runtime::Scenario.gitlab_address.include?('staging.gitlab.com') }

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
        end
      end

      let(:imported_group) do
        Resource::BulkImportGroup.fabricate_via_api! do |group|
          group.api_client = api_client
          group.sandbox = sandbox
          group.source_group_path = source_group.path
        end
      end

      before do
        Runtime::Feature.enable(:bulk_import_projects)
        Runtime::Feature.enable(:top_level_group_creation_enabled) if staging?

        sandbox.add_member(user, Resource::Members::AccessLevel::MAINTAINER)

        source_project # fabricate source group and project
      end

      after do
        user.remove_via_api!
      ensure
        Runtime::Feature.disable(:bulk_import_projects)
        Runtime::Feature.disable(:top_level_group_creation_enabled) if staging?
      end

      context 'with project' do
        it 'successfully imports project' do
          expect { imported_group.import_status }.to eventually_eq('finished').within(import_wait_duration)

          imported_projects = imported_group.reload!.projects
          aggregate_failures do
            expect(imported_projects.count).to eq(1)
            expect(imported_projects.first).to eq(source_project)
          end
        end
      end
    end
  end
end
