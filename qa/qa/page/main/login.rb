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
          element :passowrd_field, 'password_field :password'
          element :sign_in_button, 'submit "Sign in"'
        end

        def initialize
          wait('.application', time: 500)
        end

        def sign_in_using_credentials
          using_wait_time 0 do
            if page.has_content?('Change your password')
              fill_in :user_password, with: Runtime::User.password
              fill_in :user_password_confirmation, with: Runtime::User.password
              click_button 'Change your password'
            end

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
