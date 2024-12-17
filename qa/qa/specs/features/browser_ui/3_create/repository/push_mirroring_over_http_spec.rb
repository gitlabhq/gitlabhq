# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Push mirror a repository over HTTP', product_group: :source_code do
      let(:user) { Runtime::User::Store.test_user }

      it('configures and syncs a (push) mirrored repository',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347741',
        quarantine: {
          only: { condition: -> { ENV['QA_RUN_TYPE'] == 'e2e-test-on-omnibus-ce' } },
          issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/412611',
          type: :investigating
        }
      ) do
        Flow::Login.sign_in

        target_project = create(:project, name: 'push-mirror-target-project')
        target_project_uri = target_project.repository_http_location.uri
        target_project_uri.user = user.username

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
            mirror_settings.username = user.username
            mirror_settings.password = user.password
            mirror_settings.mirror_repository
            mirror_settings.update_uri(target_project_uri)
            mirror_settings.verify_update(target_project_uri)
          end
        end

        # Check that the target project has the commit from the source
        target_project.visit!

        Page::Project::Show.perform do |project|
          expect { project.has_file?('README.md') }.to eventually_be_truthy.within(max_duration: 60, reload_page: page), "Expected a file named README.md but it did not appear."
          expect(project).to have_content('This is a test project')
        end
      end
    end
  end
end
