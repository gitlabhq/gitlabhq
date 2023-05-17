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
            :dashboard,
            :vulnerability_report,
            :dependency_list,
            :license_compliance,
            :audit_events,
            :scan_policies,
            :on_demand_scans,
            :configuration
          ].each { |id| add_item(::Sidebars::NilMenuItem.new(item_id: id)) }
        end
      end
    end
  end
end
