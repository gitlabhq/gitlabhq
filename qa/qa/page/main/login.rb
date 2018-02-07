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

        def initialize
          wait(max: 500) do
            page.has_css?('.application')
          end
        end

        def sign_in_using_ldap_credentials
          click_link 'LDAP'

          fill_in :username, with: Runtime::User.name
          fill_in :password, with: Runtime::User.password

          click_button 'Sign in'
        end

        def sign_in_using_credentials
          using_wait_time 0 do
            if page.has_content?('Change your password')
              fill_in :user_password, with: Runtime::User.password
              fill_in :user_password_confirmation, with: Runtime::User.password
              click_button 'Change your password'
            end

            click_link 'Standard' if page.has_content?('LDAP')

            fill_in :user_login, with: Runtime::User.name
            fill_in :user_password, with: Runtime::User.password
            click_button 'Sign in'
          end
        end

        def self.path
          '/users/sign_in'
        end
      end
    end
  end
end
