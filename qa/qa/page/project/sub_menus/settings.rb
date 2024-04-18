# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module Settings
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.class_eval do
              include QA::Page::SubMenus::Settings
            end
          end

          def go_to_merge_request_settings
            open_settings_submenu('Merge requests')
          end

          def go_to_monitor_settings
            open_settings_submenu('Monitor')
          end

          def go_to_analytics_settings
            open_settings_submenu('Analytics')
          end

          private

          def open_settings_submenu(sub_menu)
            open_submenu('Settings', sub_menu)
          end
        end
      end
    end
  end
end
