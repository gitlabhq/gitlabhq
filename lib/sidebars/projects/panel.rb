# frozen_string_literal: true

module Sidebars
  module Projects
    class Panel < ::Sidebars::Panel
      override :configure_menus
      def configure_menus
        set_scope_menu(Sidebars::Projects::Menus::ScopeMenu.new(context))

        add_menu(Sidebars::Projects::Menus::ProjectOverviewMenu.new(context))
        add_menu(Sidebars::Projects::Menus::LearnGitlabMenu.new(context))
        add_menu(Sidebars::Projects::Menus::RepositoryMenu.new(context))
        add_menu(Sidebars::Projects::Menus::IssuesMenu.new(context))
        add_menu(Sidebars::Projects::Menus::ExternalIssueTrackerMenu.new(context))
        add_menu(Sidebars::Projects::Menus::LabelsMenu.new(context))
        add_menu(Sidebars::Projects::Menus::MergeRequestsMenu.new(context))
        add_menu(Sidebars::Projects::Menus::CiCdMenu.new(context))
        add_menu(Sidebars::Projects::Menus::SecurityComplianceMenu.new(context))
        add_menu(Sidebars::Projects::Menus::OperationsMenu.new(context))
        add_menu(Sidebars::Projects::Menus::InfrastructureMenu.new(context))
        add_menu(Sidebars::Projects::Menus::PackagesRegistriesMenu.new(context))
        add_menu(Sidebars::Projects::Menus::AnalyticsMenu.new(context))
        add_menu(confluence_or_wiki_menu)
        add_menu(Sidebars::Projects::Menus::ExternalWikiMenu.new(context))
        add_menu(Sidebars::Projects::Menus::SnippetsMenu.new(context))
        add_menu(Sidebars::Projects::Menus::MembersMenu.new(context))
        add_menu(Sidebars::Projects::Menus::SettingsMenu.new(context))
      end

      override :render_raw_menus_partial
      def render_raw_menus_partial
        'layouts/nav/sidebar/project_menus'
      end

      override :aria_label
      def aria_label
        _('Project navigation')
      end

      private

      def confluence_or_wiki_menu
        confluence_menu = ::Sidebars::Projects::Menus::ConfluenceMenu.new(context)

        confluence_menu.render? ? confluence_menu : Sidebars::Projects::Menus::WikiMenu.new(context)
      end
    end
  end
end

Sidebars::Projects::Panel.prepend_if_ee('EE::Sidebars::Projects::Panel')
