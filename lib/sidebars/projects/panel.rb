# frozen_string_literal: true

module Sidebars
  module Projects
    class Panel < ::Sidebars::Panel
      override :configure_menus
      def configure_menus
        set_scope_menu(Sidebars::Projects::Menus::ScopeMenu.new(context))
        set_hidden_menu(Sidebars::Projects::Menus::HiddenMenu.new(context))
        add_menus
      end

      override :aria_label
      def aria_label
        _('Project navigation')
      end

      private

      def add_menus
        add_menu(Sidebars::Projects::Menus::ProjectInformationMenu.new(context))
        add_menu(Sidebars::Projects::Menus::RepositoryMenu.new(context))
        add_menu(Sidebars::Projects::Menus::IssuesMenu.new(context))
        add_menu(Sidebars::Projects::Menus::ExternalIssueTrackerMenu.new(context))
        add_menu(Sidebars::Projects::Menus::ZentaoMenu.new(context))
        add_menu(Sidebars::Projects::Menus::MergeRequestsMenu.new(context))
        add_menu(Sidebars::Projects::Menus::CiCdMenu.new(context))
        add_menu(Sidebars::Projects::Menus::SecurityComplianceMenu.new(context))
        add_menu(Sidebars::Projects::Menus::DeploymentsMenu.new(context))
        add_menu(Sidebars::Projects::Menus::PackagesRegistriesMenu.new(context))
        add_menu(Sidebars::Projects::Menus::InfrastructureMenu.new(context))
        add_menu(Sidebars::Projects::Menus::MonitorMenu.new(context))
        add_menu(Sidebars::Projects::Menus::AnalyticsMenu.new(context))
        add_wiki_menus
        add_menu(Sidebars::Projects::Menus::SnippetsMenu.new(context))
        add_menu(Sidebars::Projects::Menus::SettingsMenu.new(context))
      end

      def add_wiki_menus
        add_menu((third_party_wiki_menu || Sidebars::Projects::Menus::WikiMenu).new(context))
        add_menu(Sidebars::Projects::Menus::ExternalWikiMenu.new(context))
      end

      def third_party_wiki_menu
        return unless ::Sidebars::Projects::Menus::ConfluenceMenu.new(context).render?

        ::Sidebars::Projects::Menus::ConfluenceMenu
      end
    end
  end
end

Sidebars::Projects::Panel.prepend_mod_with('Sidebars::Projects::Panel')
