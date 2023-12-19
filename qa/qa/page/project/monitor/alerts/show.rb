# frozen_string_literal: true

module QA
  module Page
    module Project
      module Monitor
        module Alerts
          class Show < Page::Base
            view 'app/assets/javascripts/vue_shared/alert_details/components/system_notes/system_note.vue' do
              element 'alert-system-note-container'
            end

            def go_to_activity_feed_tab
              click_link_with_text('Activity feed')
            end

            def has_system_note?(text)
              has_element?('alert-system-note-container', text: text)
            end
          end
        end
      end
    end
  end
end
