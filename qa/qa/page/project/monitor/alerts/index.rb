# frozen_string_literal: true

module QA
  module Page
    module Project
      module Monitor
        module Alerts
          class Index < Page::Base
            view 'app/assets/javascripts/alert_management/components/alert_management_table.vue' do
              element :alert_table_container, required: true
            end

            def has_alert_with_title?(title)
              has_link?(title, wait: 5)
            end
          end
        end
      end
    end
  end
end
