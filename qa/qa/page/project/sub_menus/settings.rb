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
              include QA::Page::Project::SubMenus::Common
            end
          end

          def go_to_ci_cd_settings
            hover_settings do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'CI/CD')
              end
            end
          end

          def go_to_repository_settings
            hover_settings do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Repository')
              end
            end
          end

          def go_to_general_settings
            hover_settings do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'General')
              end
            end
          end

          def click_settings
            within_sidebar do
              click_element(:sidebar_menu_link, menu_item: 'Settings')
            end
          end

          def go_to_integrations_settings
            hover_settings do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Integrations')
              end
            end
          end

          def go_to_monitor_settings
            hover_settings do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Monitor')
              end
            end
          end

          def go_to_access_token_settings
            hover_settings do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Access Tokens')
              end
            end
          end

          private

          def hover_settings
            within_sidebar do
              scroll_to_element(:sidebar_menu_link, menu_item: 'Settings')
              find_element(:sidebar_menu_link, menu_item: 'Settings').hover

              yield
            end
          end
        end
      end
    end
  end
end
