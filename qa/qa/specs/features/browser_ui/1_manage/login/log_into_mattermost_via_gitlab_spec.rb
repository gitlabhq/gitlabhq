# frozen_string_literal: true

module QA
  context 'Manage', :orchestrated, :mattermost do
    describe 'Mattermost login' do
      it 'user logs into Mattermost using GitLab OAuth' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        Runtime::Browser.visit(:mattermost, Page::Mattermost::Login)
        Page::Mattermost::Login.perform(&:sign_in_using_oauth)

        Page::Mattermost::Main.perform do |page|
          expect(page).to have_content(/(Welcome to: Mattermost|Logout GitLab Mattermost)/)
        end
      end
    end
  end
end
