# frozen_string_literal: true

module QA
  RSpec.shared_context 'with gitlab project migration' do
    # gitlab project migration doesn't work on just the projects
    # so all project migration tests will always require setup for gitlab group migration
    include_context "with gitlab group migration"

    let(:source_project_with_readme) { false }

    let(:source_project) do
      create(:project,
        api_client: source_admin_api_client,
        group: source_group,
        initialize_with_readme: source_project_with_readme)
    end

    let(:imported_projects) { imported_group.reload!.projects }
    let(:imported_project) { imported_projects.first }

    def expect_project_import_finished_successfully
      expect_group_import_finished_successfully
      expect(imported_projects.count).to eq(1), "Expected to have 1 imported project. Found: #{imported_projects.count}"
    end

    before do
      source_project # fabricate source group and project
    end
  end
end
