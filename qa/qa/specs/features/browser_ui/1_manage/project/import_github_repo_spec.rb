# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', :github, :requires_admin do
    describe 'Project import' do
      let(:github_repo) { 'gitlab-qa-github/test-project' }
      let(:imported_project_name) { 'imported-project' }
      let(:api_client) { Runtime::API::Client.as_admin }
      let(:group) { Resource::Group.fabricate_via_api! { |resource| resource.api_client = api_client } }
      let(:user) do
        Resource::User.fabricate_via_api! do |resource|
          resource.api_client = api_client
          resource.hard_delete_on_api_removal = true
        end
      end

      let(:imported_project) do
        Resource::ProjectImportedFromGithub.init do |project|
          project.import = true
          project.add_name_uuid = false
          project.name = imported_project_name
          project.group = group
          project.github_personal_access_token = Runtime::Env.github_access_token
          project.github_repository_path = github_repo
        end
      end

      before do
        group.add_member(user, Resource::Members::AccessLevel::MAINTAINER)

        Flow::Login.sign_in(as: user)
        Page::Main::Menu.perform(&:go_to_create_project)
        Page::Project::New.perform do |project_page|
          project_page.click_import_project
          project_page.click_github_link
        end
      end

      after do
        user.remove_via_api!
      end

      it 'imports a GitHub repo', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1762' do
        Page::Project::Import::Github.perform do |import_page|
          import_page.add_personal_access_token(Runtime::Env.github_access_token)
          import_page.import!(github_repo, group.full_path, imported_project_name)

          aggregate_failures do
            expect(import_page).to have_imported_project(github_repo)
            # validate button is present instead of navigating to avoid dealing with multiple tabs
            # which makes the test more complicated
            expect(import_page).to have_go_to_project_button(github_repo)
          end
        end

        imported_project.reload!.visit!
        Page::Project::Show.perform do |project|
          aggregate_failures do
            expect(project).to have_content(imported_project_name)
            expect(project).to have_content('This test project is used for automated GitHub import by GitLab QA.')
          end
        end
      end
    end
  end
end
