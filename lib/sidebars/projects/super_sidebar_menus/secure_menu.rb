# frozen_string_literal: true

module Sidebars
  module Projects
    module SuperSidebarMenus
      class SecureMenu < ::Sidebars::Menu
        override :title
        def title
          s_('Navigation|Secure')
        end

        override :sprite_icon
        def sprite_icon
          'shield'
        end

        override :configure_menu_items
        def configure_menu_items
          [
            :discover_project_security,
            :audit_events,
            :dashboard,
            :vulnerability_report,
            :on_demand_scans,
            :scan_policies,
            :dependency_list,
            :license_compliance,
            :configuration
          ].each { |id| add_item(::Sidebars::NilMenuItem.new(item_id: id)) }
        end
      end
    end
  end
end
