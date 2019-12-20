# frozen_string_literal: true

module QA
  context 'Create' do
    describe 'Git push over HTTP', :ldap_no_tls do
      it 'user using a personal access token pushes code to the repository' do
        Flow::Login.sign_in

        access_token = Resource::PersonalAccessToken.fabricate!.access_token

        user = Resource::User.new.tap do |user|
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

        expect(page).to have_content('README.md')
        expect(page).to have_content('This is a test project')
      end
    end
  end
end
