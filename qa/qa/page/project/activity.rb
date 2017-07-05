module QA
  module Page
    module Project
      class Activity < Page::Base
        def visit_activity_page
          click_on 'Activity'
        end

        def filter_by_push_events
          click_on 'Push events'
        end
      end
    end
  end
end
