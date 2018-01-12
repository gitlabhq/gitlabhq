module QA
  module Page
    module Activity
      class Activity < Page::Base
        view 'app/views/projects/activity.html.haml' do
          element :push_events_button, 'Push events'
        end

        def go_to_push_events
          click_button :push_events_button
        end
      end
    end
  end
end
