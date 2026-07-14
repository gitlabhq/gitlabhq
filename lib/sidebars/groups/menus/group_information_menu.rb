# frozen_string_literal: true

module Sidebars
  module Groups
    module Menus
      class GroupInformationMenu < ::Sidebars::Menu
        override :configure_menu_items
        def configure_menu_items
          add_item(activity_menu_item)
          add_item(labels_menu_item)
          add_item(members_menu_item)
          add_item(achievements_menu_item)

          true
        end

        override :title
        def title
          context.group.subgroup? ? _('Subgroup information') : _('Group information')
        end

        override :sprite_icon
        def sprite_icon
          context.group.subgroup? ? 'subgroup' : 'group'
        end

        override :active_routes
        def active_routes
          { path: 'groups#subgroups' }
        end

        override :serialize_as_menu_item_args
        def serialize_as_menu_item_args
          nil
        end

        private

        def activity_menu_item
          unless can?(context.current_user, :read_group_activity, context.group)
            return ::Sidebars::NilMenuItem.new(item_id: :activity)
          end

          ::Sidebars::MenuItem.new(
            title: _('Activity'),
            link: activity_group_path(context.group),
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ManageMenu,
            active_routes: { path: 'groups#activity' },
            item_id: :activity,
            description: _('Track what your team is working on and stay informed of changes'),
            library_icon: 'history'
          )
        end

        def labels_menu_item
          unless can?(context.current_user, :read_group_labels, context.group)
            return ::Sidebars::NilMenuItem.new(item_id: :labels)
          end

          ::Sidebars::MenuItem.new(
            title: _('Labels'),
            link: group_labels_path(context.group),
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ManageMenu,
            active_routes: { controller: :labels },
            item_id: :labels,
            description: _('Organize and categorize work across your group with consistent labels'),
            library_icon: 'labels'
          )
        end

        def members_menu_item
          unless can?(context.current_user, :read_group_member, context.group)
            return ::Sidebars::NilMenuItem.new(item_id: :members)
          end

          ::Sidebars::MenuItem.new(
            title: _('Members'),
            link: group_group_members_path(context.group),
            sprite_icon: nil,
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ManageMenu,
            active_routes: { path: 'group_members#index' },
            item_id: :members,
            description: _('Control who has access to your group and what they can do'),
            library_icon: 'users'
          )
        end

        def achievements_menu_item
          unless can?(context.current_user, :read_achievement, context.group)
            return ::Sidebars::NilMenuItem.new(item_id: :achievements)
          end

          ::Sidebars::MenuItem.new(
            title: _('Achievements'),
            link: group_achievements_path(context.group),
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::ManageMenu,
            active_routes: { controller: :achievements },
            item_id: :achievements,
            description: _('View achievements earned by your group'),
            library_icon: 'star'
          )
        end
      end
    end
  end
end
