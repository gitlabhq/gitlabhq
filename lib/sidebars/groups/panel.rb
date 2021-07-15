# frozen_string_literal: true

module Sidebars
  module Groups
    class Panel < ::Sidebars::Panel
      override :render_raw_scope_menu_partial
      def render_raw_scope_menu_partial
        'layouts/nav/sidebar/group_scope_menu'
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
