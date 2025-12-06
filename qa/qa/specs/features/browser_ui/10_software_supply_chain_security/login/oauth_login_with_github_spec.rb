# frozen_string_literal: true

module QA
  RSpec.describe 'Software Supply Chain Security', :orchestrated, :oauth, feature_category: :system_access do
    describe 'OAuth' do
      it 'connects and logs in with GitHub OAuth',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/402405',
        quarantine: {
          issue: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/work_items/17856',
          type: :stale
        } do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)

        Page::Main::Login.perform(&:sign_in_with_github)

        Vendor::Github::Page::Login.perform(&:login)
        Page::Main::Menu.perform(&:dismiss_welcome_modal_if_present)

        # After OAuth login, user might be on profile page or dashboard
        # Check that we're logged in by verifying the user menu is present
        Page::Main::Menu.perform do |menu|
          expect(menu).to be_signed_in
        end
      end
    end
  end
end
