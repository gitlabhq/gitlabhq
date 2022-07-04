# frozen_string_literal: true

module QA
  # Disable on live envs until bulk_import_projects toggle is on by default
  # Otherwise tests running in parallel can disable feature in the middle of other test
  RSpec.shared_context 'with gitlab project migration', requires_admin: 'creates a user via API',
                                                        feature_flag: {
                                                          name: 'bulk_import_projects',
                                                          scope: :global
                                                        } do
    let(:source_project_with_readme) { false }
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

    let(:destination_group) do
      Resource::Group.fabricate_via_api! do |group|
        group.api_client = api_client
        group.sandbox = sandbox
        group.path = "destination-group-for-import-#{SecureRandom.hex(4)}"
      end
    end

    let(:source_group) do
      Resource::Group.fabricate_via_api! do |group|
        group.api_client = api_client
        group.path = "source-group-for-import-#{SecureRandom.hex(4)}"
      end
    end

    let(:source_project) do
      Resource::Project.fabricate_via_api! do |project|
        project.api_client = api_client
        project.group = source_group
        project.initialize_with_readme = source_project_with_readme
      end
    end

    let(:imported_group) do
      Resource::BulkImportGroup.fabricate_via_api! do |group|
        group.api_client = api_client
        group.sandbox = destination_group
        group.source_group = source_group
      end
    end

    let(:imported_projects) { imported_group.reload!.projects }
    let(:imported_project) { imported_projects.first }

    let(:import_failures) do
      imported_group.import_details.sum([]) { |details| details[:failures] }
    end

    def expect_import_finished
      imported_group # trigger import

      expect { imported_group.import_status }.to eventually_eq('finished').within(import_wait_duration)
      expect(imported_projects.count).to eq(1), "Expected to have 1 imported project. Found: #{imported_projects.count}"
    end

    before do
      Runtime::Feature.enable(:bulk_import_projects)

      sandbox.add_member(user, Resource::Members::AccessLevel::MAINTAINER)
      source_project # fabricate source group and project
    end

    after do |example|
      # Checking for failures in the test currently makes test very flaky due to catching unrelated failures
      # Log failures for easier debugging
      Runtime::Logger.warn("Import failures: #{import_failures}") if example.exception && !import_failures.empty?
    ensure
      user.remove_via_api!
    end
  end
end
