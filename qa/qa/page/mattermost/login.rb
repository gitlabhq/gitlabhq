module QA
  module Page
    module Mattermost
      class Login < Page::Base
        def initialize
          visit(Runtime::Scenario.mattermost_address + '/login')
        end

        def sign_in_using_oauth
          click_link class: 'btn btn-custom-login gitlab'

          if page.has_content?('Authorize GitLab Mattermost to use your account?')
            click_button 'Authorize'
          end
        end
      end
    end
  end
end
