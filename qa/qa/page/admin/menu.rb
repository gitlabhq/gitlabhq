# frozen_string_literal: true

module QA
  module Page
    module Admin
      class Menu < Page::Base
        view 'app/views/layouts/nav/sidebar/_admin.html.haml' do
          element :admin_sidebar
          element :admin_sidebar_settings_submenu_content
          element :admin_settings_item
          element :admin_settings_repository_item
          element :admin_settings_general_item
          element :admin_settings_metrics_and_profiling_item
          element :admin_settings_preferences_link
          element :admin_monitoring_link
          element :admin_sidebar_monitoring_submenu_content
          element :admin_sidebar_overview_submenu_content
          element :users_overview_link
          element :groups_overview_link
          element :integration_settings_link
        end

        def go_to_preferences_settings
          hover_element(:admin_settings_item) do
            within_submenu(:admin_sidebar_settings_submenu_content) do
              click_element :admin_settings_preferences_link
            end
          end
        end

        def go_to_repository_settings
          hover_element(:admin_settings_item) do
            within_submenu(:admin_sidebar_settings_submenu_content) do
              click_element :admin_settings_repository_item
            end
          end
        end

        def go_to_integration_settings
          hover_element(:admin_settings_item) do
            within_submenu(:admin_sidebar_settings_submenu_content) do
              click_element :integration_settings_link
            end
          end
        end

        def go_to_general_settings
          hover_element(:admin_settings_item) do
            within_submenu(:admin_sidebar_settings_submenu_content) do
              click_element :admin_settings_general_item
            end
          end
        end

        def go_to_metrics_and_profiling_settings
          hover_element(:admin_settings_item) do
            within_submenu(:admin_sidebar_settings_submenu_content) do
              click_element :admin_settings_metrics_and_profiling_item
            end
          end
        end

        def go_to_network_settings
          hover_element(:admin_settings_item) do
            within_submenu(:admin_sidebar_settings_submenu_content) do
              click_element :admin_settings_network_item
            end
          end
        end

        def go_to_users_overview
          within_submenu(:admin_sidebar_overview_submenu_content) do
            click_element :users_overview_link
          end
        end

        def go_to_groups_overview
          within_submenu(:admin_sidebar_overview_submenu_content) do
            click_element :groups_overview_link
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

        def within_sidebar
          within_element(:admin_sidebar) do
            yield
          end
        end

        def within_submenu(element)
          within_element(element) do
            yield
          end
        end
      end
    end
  end
end

QA::Page::Admin::Menu.prepend_mod_with('Page::Admin::Menu', namespace: QA)
