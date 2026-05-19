# frozen_string_literal: true

module Sidebars
  module Organizations
    module Menus
      class ManageMenu < ::Sidebars::Menu
        override :title
        def title
          s_('Navigation|Manage')
        end

        override :sprite_icon
        def sprite_icon
          'users'
        end

        override :pick_into_super_sidebar?
        def pick_into_super_sidebar?
          true
        end

        override :configure_menu_items
        def configure_menu_items
          users_menu_item
        end

        private

        def users_menu_item
          return unless can?(context.current_user, :read_organization_user, context.container)

          add_item(
            ::Sidebars::MenuItem.new(
              title: _('Users'),
              link: users_organization_path(context.container),
              super_sidebar_parent: ::Sidebars::Organizations::Menus::ManageMenu,
              active_routes: { path: 'organizations/organizations#users' },
              item_id: :organization_users
            )
          )
        end
      end
    end
  end
end
