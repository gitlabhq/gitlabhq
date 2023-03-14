# frozen_string_literal: true

module Sidebars
  module Explore
    class Panel < ::Sidebars::Panel
      override :configure_menus
      def configure_menus
        add_menus
      end

      override :aria_label
      def aria_label
        _('Explore')
      end

      override :render_raw_scope_menu_partial
      def render_raw_scope_menu_partial
        "shared/nav/explore_scope_header"
      end

      override :super_sidebar_context_header
      def super_sidebar_context_header
        {
          title: aria_label,
          icon: 'compass'
        }
      end

      private

      def add_menus
        add_menu(Sidebars::Explore::Menus::ProjectsMenu.new(context))
        add_menu(Sidebars::Explore::Menus::GroupsMenu.new(context))
        add_menu(Sidebars::Explore::Menus::TopicsMenu.new(context))
        add_menu(Sidebars::Explore::Menus::SnippetsMenu.new(context))
      end
    end
  end
end
