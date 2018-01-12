module QA
  module Page
    module Activity
      class Activity < Page::Base
        ##
        # TODO, define all selectors required by this page object
        #
        # See gitlab-org/gitlab-qa#155
        #
        view 'app/views/projects/activity.html.haml'

        def go_to_push_events
          click_button 'Push events'
        end
      end
    end
  end
end
