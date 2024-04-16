# frozen_string_literal: true

module QA
  RSpec.describe 'Data Stores' do
    describe 'Project activity', :smoke, product_group: :tenant_scale do
      context 'with git push' do
        it 'creates an event in the activity page',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347879' do
          Flow::Login.sign_in

          project = Resource::Repository::ProjectPush.fabricate! do |push|
            push.file_name = 'README.md'
            push.file_content = '# This is a test project'
            push.commit_message = 'Add README.md'
          end.project

          project.visit!
          Page::Project::Menu.perform(&:go_to_activity)
          Page::Project::Activity.perform do |activity|
            activity.click_push_events

            expect(activity).to have_content("pushed new branch #{project.default_branch}")
          end
        end
      end
    end
  end
end
