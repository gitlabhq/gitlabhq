# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Git push over HTTP', product_group: :source_code do
      it 'user pushes code to the repository', :smoke, :skip_fips_env,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347747' do
        Flow::Login.sign_in

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.file_name = 'README.md'
          push.file_content = '# This is a test project'
          push.commit_message = 'Add README.md'
        end.project.visit!

        Page::Project::Show.perform do |project|
          expect(project).to have_file('README.md')
          expect(project).to have_readme_content('This is a test project')
        end
      end

      it 'pushes to a project using a specific Praefect repository storage',
        :smoke, :skip_fips_env, :requires_admin, :skip_live_env, :requires_praefect,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347789' do
        Flow::Login.sign_in_as_admin

        project = create(:project,
          name: 'specific-repository-storage',
          repository_storage: Runtime::Env.praefect_repository_storage)

        Resource::Repository::Push.fabricate! do |push|
          push.repository_http_uri = project.repository_http_location.uri
          push.file_name = 'README.md'
          push.file_content = "# This is a test project named #{project.name}"
          push.commit_message = 'Add README.md'
          push.new_branch = true
        end

        project.visit!

        Page::Project::Show.perform do |project_page|
          expect(project_page).to have_file('README.md')
          expect(project_page).to have_readme_content("This is a test project named #{project.name}")
        end
      end
    end
  end
end
