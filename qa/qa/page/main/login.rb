# frozen_string_literal: true

module QA
  module Page
    module Main
      class Login < Page::Base
        view 'app/views/devise/passwords/edit.html.haml' do
          element :password_field
          element :password_confirmation_field
          element :change_password_button
        end

        view 'app/views/devise/sessions/_new_base.html.haml' do
          element :login_field
          element :password_field
          element :sign_in_button
        end

        view 'app/views/devise/sessions/_new_ldap.html.haml' do
          element :username_field
          element :password_field
          element :sign_in_button
        end

        view 'app/views/devise/shared/_tabs_ldap.html.haml' do
          element :ldap_tab
          element :standard_tab
          element :register_tab
        end

        view 'app/views/devise/shared/_tabs_normal.html.haml' do
          element :sign_in_tab
          element :register_tab
        end

        view 'app/helpers/auth_helper.rb' do
          element :saml_login_button
          element :github_login_button
        end

        view 'app/views/layouts/devise.html.haml' do
          element :login_page, required: true
        end

        def can_sign_in?
          has_element?(:sign_in_button)
        end

        def sign_in_using_credentials(user: nil, skip_page_validation: false)
          # Don't try to log-in if we're already logged-in
          return if Page::Main::Menu.perform(&:signed_in?)

          using_wait_time 0 do
            set_initial_password_if_present

            raise NotImplementedError if Runtime::User.ldap_user? && user&.credentials_given?

            if Runtime::User.ldap_user?
              sign_in_using_ldap_credentials(user: user || Runtime::User)
            else
              sign_in_using_gitlab_credentials(user: user || Runtime::User, skip_page_validation: skip_page_validation)
            end
          end
        end

        def sign_in_using_admin_credentials
          admin = QA::Resource::User.new.tap do |user|
            user.username = QA::Runtime::User.admin_username
            user.password = QA::Runtime::User.admin_password
          end

          using_wait_time 0 do
            set_initial_password_if_present

            sign_in_using_gitlab_credentials(user: admin)
          end

          Page::Main::Menu.perform(&:has_personal_area?)
        end

        def sign_in_using_ldap_credentials(user:)
          Page::Main::Menu.perform(&:sign_out_if_signed_in)

          using_wait_time 0 do
            set_initial_password_if_present

            switch_to_ldap_tab

            fill_element :username_field, user.ldap_username
            fill_element :password_field, user.ldap_password
            click_element :sign_in_button
          end

          Page::Main::Menu.perform(&:signed_in?)
        end

        def self.path
          '/users/sign_in'
        end

        def has_sign_in_tab?
          has_element?(:sign_in_tab)
        end

        def has_ldap_tab?
          has_element?(:ldap_tab)
        end

        def has_standard_tab?
          has_element?(:standard_tab)
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

        def switch_to_sign_in_tab
          click_element :sign_in_tab
        end

        def switch_to_register_tab
          set_initial_password_if_present
          click_element :register_tab
        end

        def switch_to_ldap_tab
          click_element :ldap_tab
        end

        def switch_to_standard_tab
          click_element :standard_tab
        end

        def sign_in_with_github
          set_initial_password_if_present
          click_element :github_login_button
        end

        def sign_in_with_saml
          set_initial_password_if_present
          click_element :saml_login_button
        end

        def sign_out_and_sign_in_as(user:)
          Menu.perform(&:sign_out_if_signed_in)
          has_sign_in_tab?
          sign_in_using_credentials(user: user)
        end

        private

        def sign_in_using_gitlab_credentials(user:, skip_page_validation: false)
          switch_to_sign_in_tab if has_sign_in_tab?
          switch_to_standard_tab if has_standard_tab?

          fill_element :login_field, user.username
          fill_element :password_field, user.password
          click_element :sign_in_button, !skip_page_validation && Page::Main::Menu
        end

        def set_initial_password_if_present
          return unless has_content?('Change your password')

          fill_element :password_field, Runtime::User.password
          fill_element :password_confirmation_field, Runtime::User.password
          click_element :change_password_button
        end
      end
    end
  end
end
