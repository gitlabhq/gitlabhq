# frozen_string_literal: true

module QA
  context 'Manage', :orchestrated, :mattermost do
    describe 'Mattermost login' do
      it 'user logs into Mattermost using GitLab OAuth' do
        Flow::Login.sign_in

        Support::Retrier.retry_on_exception do
          Runtime::Browser.visit(:mattermost, Page::Mattermost::Login)
          Page::Mattermost::Login.perform(&:sign_in_using_oauth)

          Page::Mattermost::Main.perform do |mattermost|
            expect(mattermost).to have_content(/(Welcome to: Mattermost|Logout GitLab Mattermost)/)
          end
        end
      end
    end
  end
end
