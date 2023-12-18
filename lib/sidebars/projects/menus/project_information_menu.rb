# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class ProjectInformationMenu < ::Sidebars::Menu
        override :configure_menu_items
        def configure_menu_items
          add_item(activity_menu_item)
          add_item(labels_menu_item)
          add_item(members_menu_item)

          true
        end

        override :extra_container_html_options
        def extra_container_html_options
          { class: 'shortcuts-project-information' }
        end

        override :title
        def title
          _('Project information')
        end

        override :sprite_icon
        def sprite_icon
          'project'
        end

        override :serialize_as_menu_item_args
        def serialize_as_menu_item_args
          nil
        end

        private

        def activity_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Activity'),
            link: activity_project_path(context.project),
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::ManageMenu,
            active_routes: { path: 'projects#activity' },
            item_id: :activity,
            container_html_options: { class: 'shortcuts-project-activity' }
          )
        end

        def labels_menu_item
          unless can?(context.current_user, :read_label, context.project)
            return ::Sidebars::NilMenuItem.new(item_id: :labels)
          end

          ::Sidebars::MenuItem.new(
            title: _('Labels'),
            link: project_labels_path(context.project),
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::ManageMenu,
            active_routes: { controller: :labels },
            item_id: :labels
          )
        end

        def members_menu_item
          unless can?(context.current_user, :read_project_member, context.project)
            return ::Sidebars::NilMenuItem.new(item_id: :members)
          end

          ::Sidebars::MenuItem.new(
            title: _('Members'),
            link: project_project_members_path(context.project),
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::ManageMenu,
            active_routes: { controller: :project_members },
            item_id: :members
          )
        end
      end
    end
  end
end
