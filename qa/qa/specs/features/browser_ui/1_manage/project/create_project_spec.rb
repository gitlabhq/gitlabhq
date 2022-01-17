# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', :smoke do
    describe 'Project' do
      shared_examples 'successful project creation' do
        it 'creates a new project' do
          Page::Project::Show.perform do |project_page|
            expect(project_page).to have_content(project_name)
            expect(project_page).to have_content(
              /Project \S?#{project_name}\S+ was successfully created/
            )
            expect(project_page).to have_content('create awesome project test')
            expect(project_page).to have_content('The repository for this project is empty')
          end
        end
      end

      before do
        Flow::Login.sign_in
        project
      end

      context 'in group', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347876' do
        let(:project_name) { "project-in-group-#{SecureRandom.hex(8)}" }
        let(:project) do
          Resource::Project.fabricate_via_browser_ui! do |project|
            project.name = project_name
            project.description = 'create awesome project test'
          end
        end

        it_behaves_like 'successful project creation'
      end

      context 'in personal namespace', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347643' do
        let(:project_name) { "project-in-personal-namespace-#{SecureRandom.hex(8)}" }
        let(:project) do
          Resource::Project.fabricate_via_browser_ui! do |project|
            project.name = project_name
            project.description = 'create awesome project test'
            project.personal_namespace = Runtime::User.username
          end
        end

        it_behaves_like 'successful project creation'
      end

      after do
        project.remove_via_api!
      end
    end
  end
end
