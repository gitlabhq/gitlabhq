# frozen_string_literal: true

module QA
  module Page
    module Project
      class Activity < Page::Base
        view 'app/views/shared/_event_filter.html.haml' do
          element :push_events, "event_filter_link EventFilter::PUSH, _('Push events')" # rubocop:disable QA/ElementWithPattern
        end

        def click_push_events
          click_on 'Push events'
        end
      end
    end
  end
end
