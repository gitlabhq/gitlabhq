# frozen_string_literal: true

module Sidebars
  module Groups
    class Panel < ::Sidebars::Panel
      override :configure_menus
      def configure_menus
        set_scope_menu(Sidebars::Groups::Menus::ScopeMenu.new(context))

        add_menu(Sidebars::Groups::Menus::GroupInformationMenu.new(context))
        add_menu(Sidebars::Groups::Menus::IssuesMenu.new(context))
        add_menu(Sidebars::Groups::Menus::MergeRequestsMenu.new(context))
        add_menu(Sidebars::Groups::Menus::CiCdMenu.new(context))
        add_menu(Sidebars::Groups::Menus::KubernetesMenu.new(context))
        add_menu(Sidebars::Groups::Menus::PackagesRegistriesMenu.new(context))
        add_menu(Sidebars::Groups::Menus::CustomerRelationsMenu.new(context))
        add_menu(Sidebars::Groups::Menus::SettingsMenu.new(context))
      end

      override :aria_label
      def aria_label
        context.group.subgroup? ? _('Subgroup navigation') : _('Group navigation')
      end
    end
  end
end

Sidebars::Groups::Panel.prepend_mod_with('Sidebars::Groups::Panel')
