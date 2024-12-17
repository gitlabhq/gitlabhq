# frozen_string_literal: true

module QA
  module Page
    module Main
      class Login < Page::Base
        include Layout::Flash
        include Runtime::Canary

        delegate :admin_user, to: QA::Runtime::User::Store

        def self.path
          '/users/sign_in'
        end

        view 'app/views/devise/passwords/edit.html.haml' do
          element 'password-field'
          element 'password-confirmation-field'
          element 'change-password-button'
        end

        view 'app/views/devise/sessions/new.html.haml' do
          element 'register-link'
        end

        view 'app/views/devise/sessions/_new_base.html.haml' do
          element 'username-field'
          element 'password-field'
          element 'sign-in-button'
        end

        view 'app/views/devise/sessions/_new_ldap.html.haml' do
          element 'username-field'
          element 'password-field'
          element 'sign-in-button'
        end

        view 'app/views/devise/shared/_tabs_ldap.html.haml' do
          element 'ldap-tab'
          element 'standard-tab'
        end

        view 'app/views/devise/shared/_tab_single.html.haml' do
          element 'sign-in-tab'
        end

        view 'app/helpers/auth_helper.rb' do
          element 'saml-login-button'
          element 'github-login-button'
          element 'oidc-login-button'
          element 'gitlab-oauth-login-button'
        end

        view 'app/views/layouts/devise.html.haml' do
          element 'login-page', required: true
        end

        def can_sign_in?
          has_element?('sign-in-button')
        end

        def on_login_page?
          has_element?('login-page', wait: 0)
        end

        def sign_in_using_credentials(user: nil, skip_page_validation: false, raise_on_invalid_login: true)
          using_wait_time 0 do
            set_initial_password_if_present

            test_user = user || Runtime::User::Store.test_user

            if test_user.ldap_user?
              sign_in_using_ldap_credentials(user: test_user)
            else
              sign_in_using_gitlab_credentials(
                user: test_user,
                skip_page_validation: skip_page_validation,
                raise_on_invalid_login: raise_on_invalid_login
              )
            end
          end
        end

        def sign_in_using_admin_credentials
          using_wait_time 0 do
            set_initial_password_if_present
            sign_in_using_gitlab_credentials(user: admin_user)
          end

          Page::Main::Menu.perform(&:has_personal_area?)
        end

        def sign_in_using_ldap_credentials(user:)
          Page::Main::Menu.perform(&:sign_out_if_signed_in)

          using_wait_time 0 do
            set_initial_password_if_present

            switch_to_ldap_tab

            fill_element 'username-field', user.username
            fill_element 'password-field', user.password
            click_element 'sign-in-button'
          end

          Page::Main::Menu.perform(&:signed_in?)

          dismiss_duo_chat_popup if respond_to?(:dismiss_duo_chat_popup)
        end

        def has_sign_in_tab?(wait: Capybara.default_max_wait_time)
          has_element?('sign-in-tab', wait: wait)
        end

        def has_ldap_tab?
          has_element?('ldap-tab')
        end

        def has_standard_tab?
          has_element?('standard-tab')
        end

        def sign_in_tab?
          has_css?(".active", text: 'Sign in')
        end

        def ldap_tab?
          has_css?(".active", text: 'LDAP')
        end

        def standard_tab?
          has_css?(".active", text: 'Standard')
        end

        def has_accept_all_cookies_button?
          has_button?('Accept All Cookies')
        end

        def click_accept_all_cookies
          click_button('Accept All Cookies')
        end

        def switch_to_sign_in_tab
          click_element 'sign-in-tab'
        end

        def switch_to_register_page
          set_initial_password_if_present
          click_element 'register-link'
        end

        def switch_to_ldap_tab
          click_element 'ldap-tab'
        end

        def switch_to_standard_tab
          click_element 'standard-tab'
        end

        def sign_in_with_github
          set_initial_password_if_present
          click_element 'github-login-button'
        end

        def sign_in_with_saml
          set_initial_password_if_present
          click_element 'saml-login-button'
        end

        def sign_in_with_gitlab_oidc
          set_initial_password_if_present
          click_element 'oidc-login-button'
        end

        def sign_in_with_gitlab_oauth
          set_initial_password_if_present
          click_element 'gitlab-oauth-login-button'
        end

        def sign_out_and_sign_in_as(user:)
          Menu.perform(&:sign_out_if_signed_in)
          sign_in_using_credentials(user: user)
        end

        def redirect_to_login_page(address)
          Menu.perform(&:sign_out_if_signed_in)
          Runtime::Browser.visit(address, Page::Main::Login)
        end

        def set_up_new_password(user:)
          Profile::Password.perform do |new_password_page|
            password = user.password
            new_password_page.set_new_password(password, password)
          end
        end

        private

        def sign_in_using_gitlab_credentials(user:, skip_page_validation: false, raise_on_invalid_login: true)
          wait_if_retry_later

          switch_to_sign_in_tab if has_sign_in_tab?(wait: 0)
          switch_to_standard_tab if has_standard_tab?

          fill_in_credential(user)

          click_accept_all_cookies if Runtime::Env.running_on_live_env? && has_accept_all_cookies_button?

          click_element 'sign-in-button'

          Support::WaitForRequests.wait_for_requests

          wait_for_gitlab_to_respond

          if raise_on_invalid_login && has_notice?('Invalid login or password')
            raise Runtime::User::InvalidCredentialsError, "Invalid credentials for #{user.username}"
          end

          # Return if new password page is shown
          # Happens on clean GDK installations when seeded root admin password is expired
          if has_content?('Update password for', wait: 0)
            raise Runtime::User::ExpiredPasswordError, "Password for #{user.username} is expired and must be reset"
          end

          Page::Main::Terms.perform do |terms|
            terms.accept_terms if terms.visible?
          end

          Flow::UserOnboarding.onboard_user

          wait_for_gitlab_to_respond

          dismiss_duo_chat_popup if respond_to?(:dismiss_duo_chat_popup)

          return if skip_page_validation

          Page::Main::Menu.validate_elements_present!

          validate_canary!
        end

        def fill_in_credential(user)
          fill_element 'username-field', user.username
          fill_element 'password-field', user.password
        end

        def set_initial_password_if_present
          return unless has_content?('Change your password')

          fill_element 'password-field', Runtime::User.password
          fill_element 'password-confirmation-field', Runtime::User.password
          click_element 'change-password-button'
        end
      end
    end
  end
end

QA::Page::Main::Login.prepend_mod_with('Page::Main::Login', namespace: QA)
QA::Page::Main::Login.prepend_mod_with('Page::Component::DuoChatCallout', namespace: QA)
