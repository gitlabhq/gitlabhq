module QA
  module Page
    module Main
      class Login < Page::Base
        view 'app/views/devise/passwords/edit.html.haml' do
          element :txt_password, false
          element :txt_password, false
          element :btn_change_password, false
        end

        view 'app/views/devise/sessions/_new_base.html.haml' do
          element :txt_username
          element :txt_password
          element :btn_signin
        end

        view 'app/views/devise/sessions/_new_ldap.html.haml' do
          element :txt_username
          element :txt_password
          element :btn_signin
        end

        view 'app/views/devise/shared/_tabs_ldap.html.haml' do
          element :ldap_tab, false
          element :standard_tab, false
        end

        view 'app/views/devise/shared/_tabs_normal.html.haml' do
          element :tab_standard
          element :tab_register
        end

        def initialize
          # The login page is usually the entry point for all the scenarios so
          # we need to wait for the instance to start. That said, in some cases
          # we are already logged-in so we check both cases here.
          wait(max: 500) do
            page.has_css?('.login-page') ||
              Page::Menu::Main.act { has_personal_area?(wait: 0) }
          end
        end

        def sign_in_using_credentials
          # Don't try to log-in if we're already logged-in
          return if Page::Menu::Main.act { has_personal_area?(wait: 0) }

          using_wait_time 0 do
            set_initial_password_if_present

            if Runtime::User.ldap_user?
              sign_in_using_ldap_credentials
            else
              sign_in_using_gitlab_credentials
            end
          end

          Page::Menu::Main.act { has_personal_area? }
        end

        def self.path
          '/users/sign_in'
        end

        def switch_to_sign_in_tab
          click_element :tab_standard
        end

        def switch_to_register_tab
          click_element :tab_register
        end

        private

        def sign_in_using_ldap_credentials
          click_link 'LDAP'

          fill_in :username, with: Runtime::User.ldap_username
          fill_in :password, with: Runtime::User.ldap_password
          click_button 'Sign in'
        end

        def sign_in_using_gitlab_credentials
          click_link 'Standard' if page.has_content?('LDAP')

          fill_element :txt_username, Runtime::User.name
          fill_element :txt_password, Runtime::User.password
          click_element :btn_signin, Page::Menu::Main
        end

        def set_initial_password_if_present
          return unless page.has_content?('Change your password')

          fill_in :user_password, with: Runtime::User.password
          fill_in :user_password_confirmation, with: Runtime::User.password
          click_button 'Change your password'
        end
      end
    end
  end
end
