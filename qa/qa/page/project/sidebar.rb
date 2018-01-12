module QA
  module Page
    module Project
      class Sidebar < Page::Base
        ##
        # TODO, define all selectors required by this page object
        #
        # See gitlab-org/gitlab-qa#155
        #
        view 'app/views/layouts/nav/sidebar/_project.html.haml'

        def go_to_activity
          click_on class: 'shortcuts-project-activity'
        end
      end
    end
  end
end
