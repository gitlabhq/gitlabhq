# frozen_string_literal: true

module QA
  RSpec.describe 'Govern', :orchestrated, :mattermost, product_group: :authentication do
    describe 'Mattermost login' do
      it 'user logs into Mattermost using GitLab OAuth',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347891' do
        Flow::Login.sign_in

        Support::Retrier.retry_on_exception do
          Runtime::Browser.visit(:mattermost, Page::Mattermost::Login)
          Page::Mattermost::Login.perform(&:sign_in_using_oauth)

          Page::Mattermost::Main.perform do |mattermost|
            expect(mattermost).to have_content(/(GitLab Mattermost|What’s the name of your organization)/)
          end
        end
      end
    end
  end
end
