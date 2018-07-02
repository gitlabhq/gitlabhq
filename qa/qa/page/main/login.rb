module QA
  module Page
    module Main
      class Login < Page::Base
        view 'app/views/devise/passwords/edit.html.haml' do
          element :password_field, 'password_field :password'
          element :password_confirmation, 'password_field :password_confirmation'
          element :change_password_button, 'submit "Change your password"'
        end

        view 'app/views/devise/sessions/_new_base.html.haml' do
          element :login_field, 'text_field :login'
          element :password_field, 'password_field :password'
          element :sign_in_button, 'submit "Sign in"'
        end

        view 'app/views/devise/sessions/_new_ldap.html.haml' do
          element :username_field, 'text_field_tag :username'
          element :password_field, 'password_field_tag :password'
          element :sign_in_button, 'submit_tag "Sign in"'
        end

        view 'app/views/devise/shared/_tabs_ldap.html.haml' do
          element :ldap_tab, "link_to server['label']"
          element :standard_tab, "link_to 'Standard'"
        end

        view 'app/views/devise/shared/_tabs_normal.html.haml' do
          element :sign_in_tab, /nav-link.*login-pane.*Sign in/
          element :register_tab, /nav-link.*register-pane.*Register/
        end

        def initialize
          # The login page is usually the entry point for all the scenarios so
          # we need to wait for the instance to start. That said, in some cases
          # we are already logged-in so we check both cases here.
          wait.until do
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
          click_on 'Sign in'
        end

        def switch_to_register_tab
          click_on 'Register'
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

          fill_in :user_login, with: Runtime::User.name
          fill_in :user_password, with: Runtime::User.password
          click_button 'Sign in'
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
