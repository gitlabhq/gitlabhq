# frozen_string_literal: true

module Sidebars
  module Admin
    module Organizations
      class Panel < ::Sidebars::Panel
        include ::Sidebars::Concerns::SuperSidebarPanel

        override :configure_menus
        def configure_menus
          super
          set_scope_menu(Sidebars::Admin::Organizations::Menus::ScopeMenu.new(context))
          add_menu(Sidebars::StaticMenu.new(context))
          add_menu(Sidebars::Admin::Organizations::Menus::OverviewMenu.new(context))
          add_menu(Sidebars::Admin::Organizations::Menus::SettingsMenu.new(context))

          transform_old_menus(@menus, @scope_menu)
        end

        override :aria_label
        def aria_label
          s_('Organization|Organization administration')
        end

        override :super_sidebar_context_header
        def super_sidebar_context_header
          aria_label
        end
      end
    end
  end
end

Sidebars::Admin::Organizations::Panel.prepend_mod
