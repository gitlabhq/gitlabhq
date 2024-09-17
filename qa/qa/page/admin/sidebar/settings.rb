# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Sidebar
        module Settings
          def go_to_preferences_settings
            open_settings_submenu("Preferences")
          end

          def go_to_repository_settings
            open_settings_submenu("Repository")
          end

          def go_to_integration_settings
            open_settings_submenu("Integration")
          end

          def go_to_general_settings
            open_settings_submenu("General")
          end

          def go_to_metrics_and_profiling_settings
            open_settings_submenu("Metrics and profiling")
          end

          def go_to_network_settings
            open_settings_submenu("Network")
          end

          def go_to_security_and_compliance_settings
            open_settings_submenu('Security and compliance')
          end

          private

          def open_settings_submenu(sub_menu)
            open_submenu("Settings", sub_menu)
          end
        end
      end
    end
  end
end
