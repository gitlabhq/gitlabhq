# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', only: { subdomain: %i[staging staging-canary] }, quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/344213', type: :stale } do
    describe 'basic user', product_group: :authentication_and_authorization do
      it 'remains logged in when redirected from canary to non-canary node', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347626' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)

        Support::Retrier.retry_until(sleep_interval: 0.5) do
          Page::Main::Login.perform(&:can_sign_in?)
        end

        Runtime::Browser::Session.target_canary(true)
        Flow::Login.sign_in

        verify_session_on_canary(true)

        Runtime::Browser::Session.target_canary(false)

        verify_session_on_canary(false)

        Support::Retrier.retry_until(sleep_interval: 0.5) do
          Page::Main::Menu.perform(&:sign_out)

          Page::Main::Login.perform(&:can_sign_in?)
        end
      end

      def verify_session_on_canary(enable_canary)
        Page::Main::Menu.perform do |menu|
          aggregate_failures 'testing session log in' do
            expect(menu.canary?).to be(enable_canary)
            expect(menu).to have_personal_area
          end
        end
      end
    end
  end
end
