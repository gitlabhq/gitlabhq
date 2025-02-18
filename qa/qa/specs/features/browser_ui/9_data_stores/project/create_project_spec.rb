# frozen_string_literal: true

module QA
  RSpec.describe 'Data Stores', :smoke, product_group: :tenant_scale, feature_flag: {
    name: 'new_project_creation_form'
  } do
    describe 'Project' do
      shared_examples 'successful project creation' do
        it 'creates a new project' do
          Page::Project::Show.perform do |project_page|
            expect(project_page).to have_content(project_name)
            expect(project_page).to have_content('The repository for this project is empty')
          end
        end
      end

      before do
        Runtime::Feature.disable(:new_project_creation_form)
        Flow::Login.sign_in
        project
      end

      context 'in group', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347876' do
        let(:project_name) { "project-in-group-#{SecureRandom.hex(8)}" }
        let(:project) do
          Resource::Project.fabricate_via_browser_ui! do |project|
            project.name = project_name
            project.description = nil
          end
        end

        it_behaves_like 'successful project creation'
      end

      context 'in personal namespace', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347643' do
        let(:project_name) { "project-in-personal-namespace-#{SecureRandom.hex(8)}" }
        let(:project) do
          Resource::Project.fabricate_via_browser_ui! do |project|
            project.name = project_name
            project.personal_namespace = Runtime::User::Store.test_user.username
            project.description = nil
          end
        end

        it_behaves_like 'successful project creation'
      end
    end
  end
end
