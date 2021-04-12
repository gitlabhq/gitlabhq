# frozen_string_literal: true

module Sidebars
  module Projects
    class Panel < ::Sidebars::Panel
      override :render_raw_menus_partial
      def render_raw_scope_menu_partial
        'layouts/nav/sidebar/project_scope_menu'
      end

      override :render_raw_menus_partial
      def render_raw_menus_partial
        'layouts/nav/sidebar/project_menus'
      end

      override :aria_label
      def aria_label
        _('Project navigation')
      end
    end
  end
end
