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
          groups_and_projects_menu_item
        end

        private

        def groups_and_projects_menu_item
          add_item(
            ::Sidebars::MenuItem.new(
              title: _('Groups and projects'),
              link: groups_and_projects_organization_path(context.container),
              super_sidebar_parent: ::Sidebars::Organizations::Menus::ManageMenu,
              active_routes: {
                path: %w[
                  organizations/organizations#groups_and_projects
                  organizations/groups#new
                  organizations/projects#edit
                  organizations/groups#edit
                ]
              },
              item_id: :organization_groups_and_projects
            )
          )
        end
      end
    end
  end
end
