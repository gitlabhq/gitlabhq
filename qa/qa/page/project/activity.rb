module QA
  module Page
    module Project
      class Activity < Page::Base
        view 'app/views/shared/_event_filter.html.haml' do
          ##
          # TODO, This needs improvement, _event_filter.html.haml
          # doesn't have proper elements defined
          #
          element :push_events, '.event-filter'
        end

        def go_to_push_events
          click_on 'Push events'
        end
      end
    end
  end
end
