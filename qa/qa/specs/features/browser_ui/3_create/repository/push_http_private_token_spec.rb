# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Git push over HTTP', :smoke do
      it 'user using a personal access token pushes code to the repository', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1848' do
        Flow::Login.sign_in

        access_token = Resource::PersonalAccessToken.fabricate!.token

        user = Resource::User.init do |user|
          user.username = Runtime::User.username
          user.password = access_token
        end

        push = Resource::Repository::ProjectPush.fabricate! do |push|
          push.user = user
          push.file_name = 'README.md'
          push.file_content = '# This is a test project'
          push.commit_message = 'Add README.md'
        end

        push.project.visit!

        Page::Project::Show.perform(&:wait_for_viewers_to_load)

        Page::Project::Show.perform do |project|
          expect(project).to have_file('README.md')
          expect(project).to have_readme_content('This is a test project')
        end
      end
    end
  end
end
