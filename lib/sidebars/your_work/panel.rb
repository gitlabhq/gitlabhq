# frozen_string_literal: true

module Sidebars
  module YourWork
    class Panel < ::Sidebars::Panel
      override :configure_menus
      def configure_menus
        add_menus
      end

      override :aria_label
      def aria_label
        _('Your work')
      end

      override :super_sidebar_context_header
      def super_sidebar_context_header
        aria_label
      end

      private

      def add_menus
        return unless context.current_user

        add_menu(Sidebars::YourWork::Menus::ProjectsMenu.new(context))
        add_menu(Sidebars::YourWork::Menus::GroupsMenu.new(context))
        add_menu(Sidebars::YourWork::Menus::OrganizationsMenu.new(context))
        add_menu(Sidebars::YourWork::Menus::IssuesMenu.new(context))
        add_menu(Sidebars::YourWork::Menus::MergeRequestsMenu.new(context))
        add_menu(Sidebars::YourWork::Menus::TodosMenu.new(context))
        add_menu(Sidebars::YourWork::Menus::MilestonesMenu.new(context))
        add_menu(Sidebars::YourWork::Menus::SnippetsMenu.new(context))
        add_menu(Sidebars::YourWork::Menus::ActivityMenu.new(context))
        add_menu(Sidebars::YourWork::Menus::ImportHistoryMenu.new(context))
      end
    end
  end
end
Sidebars::YourWork::Panel.prepend_mod_with('Sidebars::YourWork::Panel')
