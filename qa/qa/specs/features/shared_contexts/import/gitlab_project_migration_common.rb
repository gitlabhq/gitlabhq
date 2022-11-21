# frozen_string_literal: true

module QA
  RSpec.shared_context 'with gitlab project migration' do
    # gitlab project migration doesn't work on just the projects
    # so all project migration tests will always require setup for gitlab group migration
    include_context "with gitlab group migration"

    let(:source_project_with_readme) { false }

    let(:source_project) do
      Resource::Project.fabricate_via_api! do |project|
        project.api_client = source_admin_api_client
        project.group = source_group
        project.initialize_with_readme = source_project_with_readme
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
      Runtime::Feature.enable(:bulk_import_projects) unless Runtime::Feature.enabled?(:bulk_import_projects)
      source_project # fabricate source group and project
    end
  end
end
