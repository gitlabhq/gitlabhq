# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class IssuesMenu < ::Sidebars::Menu
        include Gitlab::Utils::StrongMemoize

        override :configure_menu_items
        def configure_menu_items
          return false unless show_issues_menu_items?

          add_item(list_menu_item)
          add_item(boards_menu_item)
          add_item(service_desk_menu_item)
          add_item(milestones_menu_item)

          true
        end

        override :extra_container_html_options
        def extra_container_html_options
          {
            class: 'shortcuts-issues'
          }
        end

        override :title
        def title
          _('Issues')
        end

        override :sprite_icon
        def sprite_icon
          'issues'
        end

        override :active_routes
        def active_routes
          { path: %w[projects/issues#index projects/issues#show projects/issues#new] }
        end

        override :has_pill?
        def has_pill?
          strong_memoize(:has_pill) do
            context.project.issues_enabled?
          end
        end

        override :pill_count_field
        def pill_count_field
          'openIssuesCount'
        end

        override :pill_html_options
        def pill_html_options
          {
            class: 'issue_counter'
          }
        end

        override :serialize_as_menu_item_args
        def serialize_as_menu_item_args
          super.merge({
            pill_count: pill_count,
            pill_count_field: pill_count_field,
            has_pill: has_pill?,
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::PlanMenu,
            item_id: :project_issue_list
          })
        end

        private

        def show_issues_menu_items?
          can?(context.current_user, :read_issue, context.project)
        end

        def multi_issue_boards?
          context.project.multiple_issue_boards_available?
        end

        def list_menu_item
          ::Sidebars::MenuItem.new(
            title: _('List'),
            link: project_issues_path(context.project),
            super_sidebar_parent: ::Sidebars::NilMenuItem,
            active_routes: { path: 'projects/issues#index' },
            container_html_options: { aria: { label: _('Issues') } },
            item_id: :issue_list
          )
        end

        def boards_menu_item
          title = if context.is_super_sidebar
                    multi_issue_boards? ? s_('Issue boards') : s_('Issue board')
                  else
                    multi_issue_boards? ? s_('Boards|Boards') : s_('Boards|Board')
                  end

          ::Sidebars::MenuItem.new(
            title: title,
            link: project_boards_path(context.project),
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::PlanMenu,
            active_routes: { controller: :boards },
            container_html_options: { class: 'shortcuts-issue-boards' },
            item_id: :boards
          )
        end

        def service_desk_menu_item
          return ::Sidebars::NilMenuItem.new(item_id: :service_desk) unless ::ServiceDesk.enabled?(context.project)

          ::Sidebars::MenuItem.new(
            title: _('Service Desk'),
            link: service_desk_project_issues_path(context.project),
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::MonitorMenu,
            active_routes: { path: 'issues#service_desk' },
            item_id: :service_desk
          )
        end

        def milestones_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Milestones'),
            link: project_milestones_path(context.project),
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::PlanMenu,
            active_routes: { controller: :milestones },
            item_id: :milestones
          )
        end
      end
    end
  end
end

Sidebars::Projects::Menus::IssuesMenu.prepend_mod_with('Sidebars::Projects::Menus::IssuesMenu')
