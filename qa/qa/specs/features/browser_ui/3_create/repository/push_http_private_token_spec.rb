# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Git push over HTTP', :smoke, :skip_fips_env, product_group: :source_code do
      let(:test_user) { Runtime::User::Store.test_user }

      it 'user using a personal access token pushes code to the repository',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347749' do
        Flow::Login.sign_in

        user = build(:user, username: test_user.username, password: test_user.api_client.personal_access_token)

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
