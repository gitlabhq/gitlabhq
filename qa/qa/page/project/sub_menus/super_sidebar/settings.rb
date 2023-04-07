# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module SuperSidebar
          module Settings
            extend QA::Page::PageConcern

            def go_to_general_settings
              open_settings_submenu('General')
            end

            def go_to_integrations_settings
              open_settings_submenu('Integrations')
            end

            def go_to_access_token_settings
              open_settings_submenu('Access Tokens')
            end

            def go_to_repository_settings
              open_settings_submenu('Repository')
            end

            def go_to_merge_request_settings
              open_settings_submenu('Merge requests')
            end

            def go_to_ci_cd_settings
              open_settings_submenu('CI/CD')
            end

            def go_to_pages_settings
              open_settings_submenu('Pages')
            end

            def go_to_monitor_settings
              open_settings_submenu('Monitor')
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
end
