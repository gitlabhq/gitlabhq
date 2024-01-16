# frozen_string_literal: true

module QA
  RSpec.describe 'Create', only: { subdomain: %i[staging staging-canary] }, product_group: :source_code do
    describe 'Git push to canary Gitaly node over HTTP' do
      it 'pushes to a project using a canary specific Gitaly repository storage', :smoke, :requires_admin, testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/351116' do
        Flow::Login.sign_in_as_admin

        project = create(:project, name: 'canary-specific-repository-storage', repository_storage: 'gitaly-cny-01-stor-gstg.c.gitlab-staging-1.internal') # TODO: move to ENV var

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
