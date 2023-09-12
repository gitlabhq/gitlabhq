# frozen_string_literal: true

module QA
  module Page
    module Project
      module Monitor
        module Alerts
          class Index < Page::Base
            view 'app/assets/javascripts/alert_management/components/alert_management_table.vue' do
              element 'alert-table-container', required: true
            end

            def has_alert_with_title?(title)
              has_link?(title, wait: 5)
            end

            def go_to_alert(title)
              click_link_with_text(title)
            end

            def has_no_alert_with_title?(title)
              has_no_link?(title, wait: 5)
            end

            def go_to_tab(name)
              click_link_with_text(name)
            end
          end
        end
      end
    end
  end
end
