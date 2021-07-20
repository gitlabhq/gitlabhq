# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', :github, :requires_admin do
    describe 'Project import' do
      let!(:api_client) { Runtime::API::Client.as_admin }
      let!(:group) { Resource::Group.fabricate_via_api! { |resource| resource.api_client = api_client } }
      let!(:user) do
        Resource::User.fabricate_via_api! do |resource|
          resource.api_client = api_client
          resource.hard_delete_on_api_removal = true
        end
      end

      let(:imported_project) do
        Resource::ProjectImportedFromGithub.fabricate_via_browser_ui! do |project|
          project.name = 'imported-project'
          project.group = group
          project.github_personal_access_token = Runtime::Env.github_access_token
          project.github_repository_path = 'gitlab-qa-github/test-project'
        end
      end

      before do
        group.add_member(user, Resource::Members::AccessLevel::MAINTAINER)
      end

      after do
        user.remove_via_api!
      end

      it 'imports a GitHub repo', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1762' do
        Flow::Login.sign_in(as: user)

        imported_project # import the project

        Page::Project::Show.perform do |project|
          expect(project).to have_content(imported_project.name)
          expect(project).to have_content('This test project is used for automated GitHub import by GitLab QA.')
        end
      end
    end
  end
end
