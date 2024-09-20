# frozen_string_literal: true

module QA
  module Page
    module SubMenus
      module Settings
        extend QA::Page::PageConcern

        def go_to_general_settings
          open_settings_submenu('General')
        end

        def go_to_integrations_settings
          open_settings_submenu('Integrations')
        end

        def go_to_webhooks_settings
          open_settings_submenu('Webhooks')
        end

        def go_to_access_token_settings
          open_settings_submenu('Access tokens')
        end

        def go_to_repository_settings
          open_settings_submenu('Repository')
        end

        def go_to_ci_cd_settings
          open_settings_submenu('CI/CD')
        end

        def go_to_package_settings
          open_settings_submenu('Packages and registries')
        end

        def go_to_workspaces_settings
          open_settings_submenu('Workspaces')
        end

        private

        def open_settings_submenu(sub_menu)
          open_submenu('Settings', sub_menu)
        end
      end
    end
  end
end
