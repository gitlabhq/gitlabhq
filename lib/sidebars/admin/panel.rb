# frozen_string_literal: true

module Sidebars
  module Admin
    class Panel < ::Sidebars::Panel
      override :configure_menus
      def configure_menus
        super
        add_menus
      end

      override :aria_label
      def aria_label
        s_("Admin|Admin Area")
      end

      override :super_sidebar_context_header
      def super_sidebar_context_header
        aria_label
      end

      def add_menus
        add_menu(Sidebars::Admin::Menus::AdminOverviewMenu.new(context))
        add_menu(Sidebars::Admin::Menus::CiCdMenu.new(context))
        add_menu(Sidebars::Admin::Menus::AnalyticsMenu.new(context))
        add_menu(Sidebars::Admin::Menus::MonitoringMenu.new(context))
        add_menu(Sidebars::Admin::Menus::MessagesMenu.new(context))
        add_menu(Sidebars::Admin::Menus::SystemHooksMenu.new(context))
        add_menu(Sidebars::Admin::Menus::ApplicationsMenu.new(context))
        add_menu(Sidebars::Admin::Menus::AbuseReportsMenu.new(context))
        add_menu(Sidebars::Admin::Menus::KubernetesMenu.new(context))
        add_menu(Sidebars::Admin::Menus::SpamLogsMenu.new(context))
        add_menu(Sidebars::Admin::Menus::DeployKeysMenu.new(context))
        add_menu(Sidebars::Admin::Menus::LabelsMenu.new(context))
        add_menu(Sidebars::Admin::Menus::AdminSettingsMenu.new(context))
      end
    end
  end
end

Sidebars::Admin::Panel.prepend_mod_with('Sidebars::Admin::Panel')
