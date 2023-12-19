# frozen_string_literal: true

module QA
  module Page
    module Admin
      class Menu < Page::Base
        include SubMenus::Common
        include Sidebar::Overview
        include Sidebar::Settings

        view 'lib/sidebars/admin/menus/admin_overview_menu.rb' do
          element 'admin-overview-submenu-content'
        end

        view 'lib/sidebars/admin/menus/analytics_menu.rb' do
          element 'admin-sidebar-analytics-submenu-content'
        end

        view 'lib/sidebars/admin/menus/monitoring_menu.rb' do
          element 'admin-monitoring-menu-link'
        end

        def go_to_applications
          click_element('nav-item-link', submenu_item: 'Applications')
        end
      end
    end
  end
end

QA::Page::Admin::Menu.prepend_mod_with('Page::Admin::Menu', namespace: QA)
