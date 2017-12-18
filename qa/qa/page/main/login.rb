module QA
  module Page
    module Main
      class Login < Page::Base
        def initialize
          wait('.application', time: 500)
        end

        def sign_in_using_credentials
          if page.has_content?('Change your password')
            fill_in :user_password, with: Runtime::User.password
            fill_in :user_password_confirmation, with: Runtime::User.password
            click_button 'Change your password'
          end

          fill_in :user_login, with: Runtime::User.name
          fill_in :user_password, with: Runtime::User.password
          click_button 'Sign in'
        end

        def self.path
          '/users/sign_in'
        end
      end
    end
  end
end
