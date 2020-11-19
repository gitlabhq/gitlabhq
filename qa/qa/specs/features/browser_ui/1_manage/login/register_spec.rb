# frozen_string_literal: true

module QA
  RSpec.shared_examples 'registration and login' do
    it 'allows the user to registers and login' do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)

      Resource::User.fabricate_via_browser_ui!

      Page::Main::Menu.perform do |menu|
        expect(menu).to have_personal_area
      end
    end
  end

  RSpec.describe 'Manage', :skip_signup_disabled, :requires_admin do
    describe 'while LDAP is enabled', :orchestrated, :ldap_no_tls, testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/935' do
      before do
        # When LDAP is enabled, a previous test might have created a token for the LDAP 'tanuki' user who is not an admin
        # So we need to set it to nil in order to create a new token for admin user so that we are able to set_application_settings
        # Also, when GITLAB_LDAP_USERNAME is provided, it is used to create a token. This also needs to be set to nil temporarily
        # for the same reason as above.

        @personal_access_token = Runtime::Env.personal_access_token
        Runtime::Env.personal_access_token = nil
        ldap_username = Runtime::Env.ldap_username
        Runtime::Env.ldap_username = nil

        disable_require_admin_approval_after_user_signup

        Runtime::Env.ldap_username = ldap_username
      end

      it_behaves_like 'registration and login'

      after do
        Runtime::Env.personal_access_token = @personal_access_token
      end
    end

    describe 'standard', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/936' do
      before(:all) do
        disable_require_admin_approval_after_user_signup
      end

      it_behaves_like 'registration and login'

      context 'when user account is deleted' do
        let(:user) do
          Resource::User.fabricate_via_api! do |resource|
            resource.api_client = admin_api_client
          end
        end

        before do
          # Use the UI instead of API to delete the account since
          # this is the only test that exercise this UI.
          # Other tests should use the API for this purpose.
          Flow::Login.sign_in(as: user)
          Page::Main::Menu.perform(&:click_settings_link)
          Page::Profile::Menu.perform(&:click_account)
          Page::Profile::Accounts::Show.perform do |show|
            show.delete_account(user.password)
          end
        end

        it 'allows recreating with same credentials', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/937' do
          expect(Page::Main::Menu.perform(&:signed_in?)).to be_falsy

          Flow::Login.sign_in(as: user, skip_page_validation: true)

          expect(page).to have_text("Invalid Login or password")

          @recreated_user = Resource::User.fabricate_via_browser_ui! do |resource|
            resource.name = user.name
            resource.username = user.username
            resource.email = user.email
          end

          expect(Page::Main::Menu.perform(&:signed_in?)).to be_truthy
        end

        after do
          @recreated_user.remove_via_api!
        end

        def admin_api_client
          @admin_api_client ||= Runtime::API::Client.as_admin
        end
      end
    end

    def disable_require_admin_approval_after_user_signup
      Runtime::ApplicationSettings.set_application_settings(require_admin_approval_after_user_signup: false)
      sleep 10 # It takes a moment for the setting to come into effect
    end
  end
end
