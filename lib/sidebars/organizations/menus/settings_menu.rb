# frozen_string_literal: true

module Sidebars
  module Organizations
    module Menus
      class SettingsMenu < ::Sidebars::Menu
        override :title
        def title
          _('Settings')
        end

        override :sprite_icon
        def sprite_icon
          'settings'
        end

        override :pick_into_super_sidebar?
        def pick_into_super_sidebar?
          true
        end

        override :render?
        def render?
          can?(context.current_user, :admin_organization, context.container)
        end

        override :configure_menu_items
        def configure_menu_items
          add_item(
            ::Sidebars::MenuItem.new(
              title: _('General'),
              link: general_settings_organization_path(context.container),
              super_sidebar_parent: ::Sidebars::Organizations::Menus::SettingsMenu,
              active_routes: { path: 'organizations/settings#general' },
              item_id: :organization_settings_general
            )
          )
        end
      end
    end
  end
end
