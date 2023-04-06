# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module SuperSidebar
          module Monitor
            extend QA::Page::PageConcern

            def go_to_metrics
              open_monitor_submenu('Metrics')
            end

            def go_to_error_tracking
              open_monitor_submenu('Error tracking')
            end

            def go_to_alerts
              open_monitor_submenu('Alerts')
            end

            def go_to_incidents
              open_monitor_submenu('Incidents')
            end

            private

            def open_monitor_submenu(sub_menu)
              open_submenu('Monitor', '#monitor', sub_menu)
            end
          end
        end
      end
    end
  end
end
