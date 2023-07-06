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
          add_item(
            ::Sidebars::MenuItem.new(
              title: _('Groups and projects'),
              link: groups_and_projects_organization_path(context.container),
              super_sidebar_parent: ::Sidebars::Organizations::Menus::ManageMenu,
              active_routes: { path: 'organizations/organizations#groups_and_projects' },
              item_id: :organization_groups_and_projects
            )
          )
        end
      end
    end
  end
end
