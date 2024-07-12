# frozen_string_literal: true

module Sidebars
  module Admin
    module Menus
      class AnalyticsMenu < ::Sidebars::Admin::BaseMenu
        override :configure_menu_items
        def configure_menu_items
          add_item(dev_ops_reports_menu_item)
          add_item(usage_trends_menu_item)

          true
        end

        override :title
        def title
          s_('Admin|Analytics')
        end

        override :sprite_icon
        def sprite_icon
          'chart'
        end

        override :extra_container_html_options
        def extra_container_html_options
          { testid: 'admin-sidebar-analytics-submenu-content' }
        end

        private

        def dev_ops_reports_menu_item
          ::Sidebars::MenuItem.new(
            title: _('DevOps Reports'),
            link: admin_dev_ops_reports_path,
            active_routes: { controller: 'dev_ops_report' },
            item_id: :dev_ops_reports,
            container_html_options: { 'data-testid': 'admin-analytics-link' }
          )
        end

        def usage_trends_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Usage trends'),
            link: admin_usage_trends_path,
            active_routes: { controller: 'usage_trends' },
            item_id: :usage_trends
          )
        end
      end
    end
  end
end
