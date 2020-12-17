# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    describe 'Project activity' do
      it 'user creates an event in the activity page upon Git push', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/407' do
        Flow::Login.sign_in

        project = Resource::Repository::ProjectPush.fabricate! do |push|
          push.file_name = 'README.md'
          push.file_content = '# This is a test project'
          push.commit_message = 'Add README.md'
        end.project

        project.visit!
        Page::Project::Menu.perform(&:click_activity)
        Page::Project::Activity.perform do |activity|
          activity.click_push_events

          expect(activity).to have_content("pushed new branch #{project.default_branch}")
        end
      end
    end
  end
end
