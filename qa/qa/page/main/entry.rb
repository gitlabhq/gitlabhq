module QA
  module Page
    module Main
      class Entry < Page::Base
        def initialize
          visit('/')

          # This resolves cold boot / background tasks problems
          #
          start = Time.now

          while Time.now - start < 240
            break if page.has_css?('.application', wait: 10)
            refresh
          end
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
      end
    end
  end
end
