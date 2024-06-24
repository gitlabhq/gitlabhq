# frozen_string_literal: true

module QA
  module Page
    module Main
      class Login < Page::Base
        include Layout::Flash
        include Runtime::Canary

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

        def sign_in_using_credentials(user: nil, skip_page_validation: false)
          # Don't try to log-in if we're already logged-in
          return if Page::Main::Menu.perform(&:signed_in?)

          using_wait_time 0 do
            set_initial_password_if_present

            if Runtime::User.ldap_user? && user && user.username != Runtime::User.ldap_username
              raise QA::Resource::User::InvalidUserError, 'If an LDAP user is provided, it must be used for sign-in'
            end

            if Runtime::User.ldap_user?
              sign_in_using_ldap_credentials(user: user || Runtime::User)
            else
              sign_in_using_gitlab_credentials(user: user || Runtime::User, skip_page_validation: skip_page_validation)
            end

            set_up_new_password_if_required(user: user, skip_page_validation: skip_page_validation)
          end
        end

        def sign_in_using_admin_credentials
          using_wait_time 0 do
            set_initial_password_if_present
            sign_in_using_gitlab_credentials(user: admin)
          end

          set_up_new_admin_password_if_required

          Page::Main::Menu.perform(&:has_personal_area?)
        end

        def sign_in_using_ldap_credentials(user:)
          Page::Main::Menu.perform(&:sign_out_if_signed_in)

          using_wait_time 0 do
            set_initial_password_if_present

            switch_to_ldap_tab

            fill_element 'username-field', user.ldap_username
            fill_element 'password-field', user.ldap_password
            click_element 'sign-in-button'
          end

          Page::Main::Menu.perform(&:signed_in?)

          dismiss_duo_chat_popup if respond_to?(:dismiss_duo_chat_popup)
        end

        # Handle request for password change
        # Happens on clean GDK installations when seeded root admin password is expired
        #
        def set_up_new_password_if_required(user:, skip_page_validation:)
          Support::WaitForRequests.wait_for_requests
          return unless has_content?('Set up new password', wait: 1)

          Profile::Password.perform do |new_password_page|
            password = user&.password || Runtime::User.password
            new_password_page.set_new_password(password, password)
          end

          sign_in_using_credentials(user: user, skip_page_validation: skip_page_validation)
        end

        def set_up_new_admin_password_if_required
          set_up_new_password_if_required(user: admin, skip_page_validation: false)
        end

        def self.path
          '/users/sign_in'
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

        private

        def admin
          @admin ||= QA::Resource::User.init do |user|
            user.username = QA::Runtime::User.admin_username
            user.password = QA::Runtime::User.admin_password
          end
        end

        def sign_in_using_gitlab_credentials(user:, skip_page_validation: false)
          wait_if_retry_later

          switch_to_sign_in_tab if has_sign_in_tab?(wait: 0)
          switch_to_standard_tab if has_standard_tab?

          fill_in_credential(user)

          click_accept_all_cookies if Runtime::Env.running_on_dot_com? && has_accept_all_cookies_button?

          click_element 'sign-in-button'

          Support::WaitForRequests.wait_for_requests

          wait_for_gitlab_to_respond

          # For debugging invalid login attempts
          has_notice?('Invalid login or password')

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
