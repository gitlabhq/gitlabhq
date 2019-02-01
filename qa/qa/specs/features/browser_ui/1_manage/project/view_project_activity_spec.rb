# frozen_string_literal: true

module QA
  context 'Manage' do
    describe 'Project activity' do
      it 'user creates an event in the activity page upon Git push' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        project_push = Resource::Repository::ProjectPush.fabricate! do |push|
          push.file_name = 'README.md'
          push.file_content = '# This is a test project'
          push.commit_message = 'Add README.md'
        end
        project_push.project.visit!

        Page::Project::Menu.perform(&:go_to_activity)
        Page::Project::Activity.perform(&:go_to_push_events)

        expect(page).to have_content('pushed new branch master')
      end
    end
  end
end
