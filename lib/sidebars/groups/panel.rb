# frozen_string_literal: true

module Sidebars
  module Groups
    class Panel < ::Sidebars::Panel
      override :configure_menus
      def configure_menus
        set_scope_menu(Sidebars::Groups::Menus::ScopeMenu.new(context))
      end

      override :render_raw_menus_partial
      def render_raw_menus_partial
        'layouts/nav/sidebar/group_menus'
      end

      override :aria_label
      def aria_label
        context.group.subgroup? ? _('Subgroup navigation') : _('Group navigation')
      end
    end
  end
end

Sidebars::Groups::Panel.prepend_mod_with('Sidebars::Groups::Panel')
