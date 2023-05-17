# frozen_string_literal: true

module QA
  module Page
    module Admin
      class Menu < Page::Base
        include SubMenus::Common

        if QA::Runtime::Env.super_sidebar_enabled?
          prepend Sidebar::Overview
          prepend Sidebar::Settings
        end

        view 'lib/sidebars/admin/menus/admin_overview_menu.rb' do
          element :admin_overview_submenu_content
        end

        view 'lib/sidebars/admin/menus/analytics_menu.rb' do
          element :admin_sidebar_analytics_submenu_content
        end

        view 'lib/sidebars/admin/menus/monitoring_menu.rb' do
          element :admin_monitoring_menu_link
        end

        def go_to_preferences_settings
          hover_element(:admin_settings_menu_link) do
            click_element :admin_settings_preferences_link
          end
        end

        def go_to_repository_settings
          hover_element(:admin_settings_menu_link) do
            click_element :admin_settings_repository_link
          end
        end

        def go_to_integration_settings
          hover_element(:admin_settings_menu_link) do
            click_element :admin_settings_integrations_link
          end
        end

        def go_to_general_settings
          hover_element(:admin_settings_menu_link) do
            click_element :admin_settings_general_link
          end
        end

        def go_to_metrics_and_profiling_settings
          hover_element(:admin_settings_menu_link) do
            click_element :admin_settings_metrics_and_profiling_link
          end
        end

        def go_to_network_settings
          hover_element(:admin_settings_menu_link) do
            click_element :admin_settings_network_link
          end
        end

        def go_to_users_overview
          click_element :admin_overview_users_link
        end

        def go_to_groups_overview
          click_element :admin_overview_groups_link
        end

        def go_to_applications
          return click_element(:nav_item_link, submenu_item: 'Applications') if Runtime::Env.super_sidebar_enabled?

          click_element(:sidebar_menu_link, menu_item: 'Applications')
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
          page.within('.sidebar-top-level-items', &block)
        end

        def within_submenu(element, &block)
          within_element(element, &block)
        end
      end
    end
  end
end

QA::Page::Admin::Menu.prepend_mod_with('Page::Admin::Menu', namespace: QA)
