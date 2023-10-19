# frozen_string_literal: true

module Sidebars
  module Organizations
    class Panel < ::Sidebars::Panel
      include ::Sidebars::Concerns::SuperSidebarPanel

      override :aria_label
      def aria_label
        s_('Organization|Organization navigation')
      end

      override :configure_menus
      def configure_menus
        set_scope_menu(Sidebars::Organizations::Menus::ScopeMenu.new(context))
        add_menu(Sidebars::StaticMenu.new(context))
        add_menu(Sidebars::Organizations::Menus::ManageMenu.new(context))
        add_menu(Sidebars::Organizations::Menus::SettingsMenu.new(context))
      end
    end
  end
end
