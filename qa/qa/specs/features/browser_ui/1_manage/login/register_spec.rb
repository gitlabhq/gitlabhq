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

        set_require_admin_approval_after_user_signup_via_api(false)

        Runtime::Env.ldap_username = ldap_username
      end

      it_behaves_like 'registration and login'

      after do
        Runtime::Env.personal_access_token = @personal_access_token
      end
    end

    describe 'standard', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/936' do
      context 'when admin approval is not required' do
        before(:all) do
          set_require_admin_approval_after_user_signup_via_api(false)
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
            Page::Main::Menu.perform(&:click_edit_profile_link)
            Page::Profile::Menu.perform(&:click_account)
            Page::Profile::Accounts::Show.perform do |show|
              show.delete_account(user.password)
            end
          end

          it 'allows recreating with same credentials', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/937' do
            expect(Page::Main::Menu.perform(&:signed_in?)).to be_falsy

            Flow::Login.sign_in(as: user, skip_page_validation: true)

            expect(page).to have_text("Invalid login or password")

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

      context 'when admin approval is required' do
        let(:signed_up_waiting_approval_text) { 'You have signed up successfully. However, we could not sign you in because your account is awaiting approval from your GitLab administrator.' }
        let(:pending_approval_blocked_text) { 'Your account is pending approval from your GitLab administrator and hence blocked. Please contact your GitLab administrator if you think this is an error.' }

        before do
          enable_require_admin_approval_after_user_signup_via_ui

          Support::Retrier.retry_on_exception do
            @user = Resource::User.fabricate_via_browser_ui! do |user|
              user.expect_fabrication_success = false
            end
          end
        end

        it 'allows user login after approval', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1076' do
          expect(page).to have_text(signed_up_waiting_approval_text)

          Flow::Login.sign_in(as: @user, skip_page_validation: true)

          expect(page).to have_text(pending_approval_blocked_text)

          approve_user(@user)

          Flow::Login.sign_in(as: @user, skip_page_validation: true)

          Page::Registration::Welcome.perform(&:click_get_started_button_if_available)

          Page::Main::Menu.perform do |menu|
            expect(menu).to have_personal_area
          end
        end

        after do
          set_require_admin_approval_after_user_signup_via_api(false)
          @user.remove_via_api! if @user
        end
      end
    end

    def approve_user(user)
      Flow::Login.while_signed_in_as_admin do
        Page::Main::Menu.perform(&:go_to_admin_area)
        Page::Admin::Menu.perform(&:go_to_users_overview)
        Page::Admin::Overview::Users::Index.perform do |index|
          index.click_pending_approval_tab
          index.search_user(user.username)
          index.click_user(user.name)
        end

        Page::Admin::Overview::Users::Show.perform do |show|
          user.id = show.user_id.to_i
          show.approve_user(user)
        end

        expect(page).to have_text('Successfully approved')
      end
    end

    def set_require_admin_approval_after_user_signup_via_api(enable_or_disable)
      return if get_require_admin_approval_after_user_signup_via_api == enable_or_disable

      Runtime::ApplicationSettings.set_application_settings(require_admin_approval_after_user_signup: enable_or_disable)

      sleep 10 # It takes a moment for the setting to come into effect
    end

    def get_require_admin_approval_after_user_signup_via_api
      Runtime::ApplicationSettings.get_application_settings[:require_admin_approval_after_user_signup]
    end

    def enable_require_admin_approval_after_user_signup_via_ui
      unless get_require_admin_approval_after_user_signup_via_api
        QA::Support::Retrier.retry_until do
          Flow::Login.while_signed_in_as_admin do
            Page::Main::Menu.perform(&:go_to_admin_area)
            QA::Page::Admin::Menu.perform(&:go_to_general_settings)
            Page::Admin::Settings::General.perform do |setting|
              setting.expand_sign_up_restrictions do |settings|
                settings.require_admin_approval_after_user_signup
              end
            end
          end

          sleep 15 # It takes a moment for the setting to come into effect

          get_require_admin_approval_after_user_signup_via_api
        end
      end
    end
  end
end
