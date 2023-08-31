# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module Monitor
          extend QA::Page::PageConcern

          def go_to_monitor_error_tracking
            open_monitor_submenu('Error tracking')
          end

          def go_to_monitor_alerts
            open_monitor_submenu('Alerts')
          end

          def go_to_monitor_incidents
            open_monitor_submenu('Incidents')
          end

          def go_to_monitor_escalation_policies
            open_monitor_submenu('Escalation Policies')
          end

          def go_to_monitor_on_call_schedules
            open_monitor_submenu('On-call Schedules')
          end

          private

          def open_monitor_submenu(sub_menu)
            open_submenu('Monitor', sub_menu)
          end
        end
      end
    end
  end
end
