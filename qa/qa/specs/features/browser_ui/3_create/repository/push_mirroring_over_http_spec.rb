# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Push mirror a repository over HTTP' do
      it 'configures and syncs a (push) mirrored repository', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/414' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        target_project = Resource::Project.fabricate_via_api! do |project|
          project.name = 'push-mirror-target-project'
        end
        target_project_uri = target_project.repository_http_location.uri
        target_project_uri.user = Runtime::User.username

        source_project_push = Resource::Repository::ProjectPush.fabricate! do |push|
          push.file_name = 'README.md'
          push.file_content = '# This is a test project'
          push.commit_message = 'Add README.md'
        end
        source_project_push.project.visit!

        Page::Project::Menu.perform(&:go_to_repository_settings)
        Page::Project::Settings::Repository.perform do |settings|
          settings.expand_mirroring_repositories do |mirror_settings|
            # Configure the source project to push to the target project
            mirror_settings.repository_url = target_project_uri
            mirror_settings.mirror_direction = 'Push'
            mirror_settings.authentication_method = 'Password'
            mirror_settings.password = Runtime::User.password
            mirror_settings.mirror_repository
            mirror_settings.update target_project_uri
          end
        end

        # Check that the target project has the commit from the source
        target_project.visit!

        Page::Project::Show.perform do |project|
          expect(project).to have_content('README.md')
          expect(project).to have_content('This is a test project')
        end
      end
    end
  end
end
