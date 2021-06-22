# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class IssuesMenu < ::Sidebars::Menu
        include Gitlab::Utils::StrongMemoize

        override :configure_menu_items
        def configure_menu_items
          return unless can?(context.current_user, :read_issue, context.project)

          add_item(list_menu_item)
          add_item(boards_menu_item)
          add_item(service_desk_menu_item)
          add_item(milestones_menu_item)

          true
        end

        override :link
        def link
          project_issues_path(context.project)
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

        override :title_html_options
        def title_html_options
          {
            id: 'js-onboarding-issues-link'
          }
        end

        override :sprite_icon
        def sprite_icon
          'issues'
        end

        override :active_routes
        def active_routes
          { controller: 'projects/issues' }
        end

        override :has_pill?
        def has_pill?
          strong_memoize(:has_pill) do
            context.project.issues_enabled?
          end
        end

        override :pill_count
        def pill_count
          strong_memoize(:pill_count) do
            context.project.open_issues_count(context.current_user)
          end
        end

        override :pill_html_options
        def pill_html_options
          {
            class: 'issue_counter'
          }
        end

        private

        def list_menu_item
          ::Sidebars::MenuItem.new(
            title: _('List'),
            link: project_issues_path(context.project),
            active_routes: { path: 'projects/issues#index' },
            container_html_options: { aria: { label: _('Issues') } },
            item_id: :issue_list
          )
        end

        def boards_menu_item
          title = context.project.multiple_issue_boards_available? ? s_('IssueBoards|Boards') : s_('IssueBoards|Board')

          ::Sidebars::MenuItem.new(
            title: title,
            link: project_boards_path(context.project),
            active_routes: { controller: :boards },
            item_id: :boards
          )
        end

        def service_desk_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Service Desk'),
            link: service_desk_project_issues_path(context.project),
            active_routes: { path: 'issues#service_desk' },
            item_id: :service_desk
          )
        end

        def milestones_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Milestones'),
            link: project_milestones_path(context.project),
            active_routes: { controller: :milestones },
            item_id: :milestones
          )
        end
      end
    end
  end
end

Sidebars::Projects::Menus::IssuesMenu.prepend_mod_with('Sidebars::Projects::Menus::IssuesMenu')
