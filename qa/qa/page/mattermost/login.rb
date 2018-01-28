module QA
  module Page
    module Mattermost
      class Login < Page::Base
        ##
        # TODO, define all selectors required by this page object
        #
        # See gitlab-org/gitlab-qa#154
        #
        view 'app/views/projects/mattermosts/new.html.haml'

        def sign_in_using_oauth
          click_link class: 'btn btn-custom-login gitlab'

          if page.has_content?('Authorize GitLab Mattermost to use your account?')
            click_button 'Authorize'
          end
        end

        def self.path
          '/login'
        end
      end
    end
  end
end
