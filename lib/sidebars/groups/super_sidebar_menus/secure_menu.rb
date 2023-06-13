# frozen_string_literal: true

module Sidebars
  module Groups
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
            :security_dashboard,
            :vulnerability_report,
            :dependency_list,
            :audit_events,
            :compliance,
            :scan_policies
          ].each { |id| add_item(::Sidebars::NilMenuItem.new(item_id: id)) }
        end
      end
    end
  end
end
