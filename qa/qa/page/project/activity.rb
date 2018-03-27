module QA
  module Page
    module Project
      class Activity < Page::Base
        view 'app/views/shared/_event_filter.html.haml' do
          element :push_events, "event_filter_link EventFilter.push, _('Push events')"
        end

        def go_to_push_events
          click_on 'Push events'
        end
      end
    end
  end
end
