# frozen_string_literal: true

module QA
  module Page
    module Admin
      class Menu < Page::Base
        view 'app/views/layouts/nav/sidebar/_admin.html.haml' do
          element :admin_sidebar_content
          element :admin_monitoring_menu_link
          element :admin_monitoring_submenu_content
          element :admin_overview_submenu_content
          element :admin_overview_users_link
          element :admin_overview_groups_link
          element :admin_settings_menu_link
          element :admin_settings_submenu_content
          element :admin_settings_general_link
          element :admin_settings_integrations_link
          element :admin_settings_metrics_and_profiling_link
          element :admin_settings_network_link
          element :admin_settings_preferences_link
          element :admin_settings_repository_link
        end

        def go_to_preferences_settings
          hover_element(:admin_settings_menu_link) do
            within_submenu(:admin_settings_submenu_content) do
              click_element :admin_settings_preferences_link
            end
          end
        end

        def go_to_repository_settings
          hover_element(:admin_settings_menu_link) do
            within_submenu(:admin_settings_submenu_content) do
              click_element :admin_settings_repository_link
            end
          end
        end

        def go_to_integration_settings
          hover_element(:admin_settings_menu_link) do
            within_submenu(:admin_settings_submenu_content) do
              click_element :admin_settings_integrations_link
            end
          end
        end

        def go_to_general_settings
          hover_element(:admin_settings_menu_link) do
            within_submenu(:admin_settings_submenu_content) do
              click_element :admin_settings_general_link
            end
          end
        end

        def go_to_metrics_and_profiling_settings
          hover_element(:admin_settings_menu_link) do
            within_submenu(:admin_settings_submenu_content) do
              click_element :admin_settings_metrics_and_profiling_link
            end
          end
        end

        def go_to_network_settings
          hover_element(:admin_settings_menu_link) do
            within_submenu(:admin_settings_submenu_content) do
              click_element :admin_settings_network_link
            end
          end
        end

        def go_to_users_overview
          within_submenu(:admin_overview_submenu_content) do
            click_element :admin_overview_users_link
          end
        end

        def go_to_groups_overview
          within_submenu(:admin_overview_submenu_content) do
            click_element :admin_overview_groups_link
          end
        end

        private

        def hover_element(element)
          within_sidebar do
            scroll_to_element(element)
            find_element(element).hover

            yield
          end
        end

        def within_sidebar(&block)
          within_element(:admin_sidebar_content, &block)
        end

        def within_submenu(element, &block)
          within_element(element, &block)
        end
      end
    end
  end
end

QA::Page::Admin::Menu.prepend_mod_with('Page::Admin::Menu', namespace: QA)
