# frozen_string_literal: true

module QA
  module Page
    module Admin
      class Menu < Page::Base
        include SubMenus::Common
        include Sidebar::Overview
        include Sidebar::Settings

        view 'lib/sidebars/admin/menus/admin_overview_menu.rb' do
          element :admin_overview_submenu_content
        end

        view 'lib/sidebars/admin/menus/analytics_menu.rb' do
          element :admin_sidebar_analytics_submenu_content
        end

        view 'lib/sidebars/admin/menus/monitoring_menu.rb' do
          element :admin_monitoring_menu_link
        end

        def go_to_applications
          click_element(:nav_item_link, submenu_item: 'Applications')
        end

        private

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
