# frozen_string_literal: true

module Sidebars
  module Organizations
    class SuperSidebarPanel < ::Sidebars::Organizations::Panel
      include ::Sidebars::Concerns::SuperSidebarPanel
      extend ::Gitlab::Utils::Override

      override :configure_menus
      def configure_menus
        super
        old_menus = @menus
        @menus = []

        add_menu(Sidebars::StaticMenu.new(context))

        # Pick old menus, will be obsolete once everything is in their own
        # super sidebar menu
        pick_from_old_menus(old_menus)

        transform_old_menus(@menus, @scope_menu, *old_menus)
      end

      override :super_sidebar_context_header
      def super_sidebar_context_header
        _('Organization')
      end
    end
  end
end
