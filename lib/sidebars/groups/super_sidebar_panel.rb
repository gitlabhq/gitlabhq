# frozen_string_literal: true

module Sidebars
  module Groups
    class SuperSidebarPanel < ::Sidebars::Groups::Panel
      include ::Sidebars::Concerns::SuperSidebarPanel
      extend ::Gitlab::Utils::Override

      override :configure_menus
      def configure_menus
        super
        old_menus = @menus
        @menus = []

        add_menu(Sidebars::StaticMenu.new(context))
        add_menu(Sidebars::Groups::SuperSidebarMenus::ManageMenu.new(context))
        add_menu(Sidebars::Groups::SuperSidebarMenus::PlanMenu.new(context))
        add_menu(Sidebars::Groups::SuperSidebarMenus::CodeMenu.new(context))
        add_menu(Sidebars::Groups::SuperSidebarMenus::BuildMenu.new(context))
        add_menu(Sidebars::Groups::SuperSidebarMenus::SecureMenu.new(context))
        add_menu(Sidebars::Groups::SuperSidebarMenus::DeployMenu.new(context))
        add_menu(Sidebars::Groups::SuperSidebarMenus::OperationsMenu.new(context))
        add_menu(Sidebars::Groups::SuperSidebarMenus::AnalyzeMenu.new(context))

        pick_from_old_menus(old_menus)

        insert_menu_before(
          Sidebars::Groups::Menus::SettingsMenu,
          Sidebars::UncategorizedMenu.new(context)
        )

        transform_old_menus(@menus, @scope_menu, *old_menus)
      end

      override :super_sidebar_context_header
      def super_sidebar_context_header
        _('Group')
      end
    end
  end
end
