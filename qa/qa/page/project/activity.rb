module QA
  module Page
    module Project
      class Activity < Page::Base
        view 'app/views/shared/_event_filter.html.haml' do
          element :push_events_button, 'Push events'
        end

        def go_to_push_events
          click_link :push_events_button
        end

        def self.path
          '/activity'
        end
      end
    end
  end
end
