# frozen_string_literal: true

module Sidebars
  module Projects
    class SuperSidebarPanel < ::Sidebars::Projects::Panel
      include ::Sidebars::Concerns::SuperSidebarPanel
      extend ::Gitlab::Utils::Override

      override :configure_menus
      def configure_menus
        super
        old_menus = @menus
        @menus = []

        add_menu(Sidebars::StaticMenu.new(context))
        add_menu(Sidebars::Projects::SuperSidebarMenus::ManageMenu.new(context))
        add_menu(Sidebars::Projects::SuperSidebarMenus::PlanMenu.new(context))
        add_menu(Sidebars::Projects::SuperSidebarMenus::CodeMenu.new(context))
        add_menu(Sidebars::Projects::SuperSidebarMenus::BuildMenu.new(context))
        add_menu(Sidebars::Projects::SuperSidebarMenus::SecureMenu.new(context))
        add_menu(Sidebars::Projects::SuperSidebarMenus::DeployMenu.new(context))
        add_menu(Sidebars::Projects::SuperSidebarMenus::OperationsMenu.new(context))
        add_menu(Sidebars::Projects::SuperSidebarMenus::MonitorMenu.new(context))
        add_menu(Sidebars::Projects::SuperSidebarMenus::AnalyzeMenu.new(context))

        add_menu(Sidebars::Projects::SuperSidebarMenus::ObserveMenu.new(context)) if observe_menu_enabled?

        # Pick old menus, will be obsolete once everything is in their own
        # super sidebar menu
        pick_from_old_menus(old_menus)

        insert_menu_before(
          Sidebars::Projects::Menus::SettingsMenu,
          Sidebars::UncategorizedMenu.new(context)
        )

        transform_old_menus(@menus, @scope_menu, *old_menus)
      end

      override :super_sidebar_context_header
      def super_sidebar_context_header
        _('Project')
      end

      private

      def observe_menu_enabled?
        if context.container.group
          ::Feature.enabled?(:observability_sass_features, context.container.group)
        else
          ::Feature.enabled?(:observability_saas_features_user_namespace, context.container.root_namespace)
        end
      end
    end
  end
end

Sidebars::Projects::SuperSidebarPanel.prepend_mod_with('Sidebars::Projects::SuperSidebarPanel')
