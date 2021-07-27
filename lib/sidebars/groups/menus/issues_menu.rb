# frozen_string_literal: true

module Sidebars
  module Groups
    module Menus
      class IssuesMenu < ::Sidebars::Menu
        include Gitlab::Utils::StrongMemoize

        override :configure_menu_items
        def configure_menu_items
          return unless can?(context.current_user, :read_group_issues, context.group)

          add_item(list_menu_item)
          add_item(boards_menu_item)
          add_item(milestones_menu_item)

          true
        end

        override :link
        def link
          issues_group_path(context.group)
        end

        override :title
        def title
          _('Issues')
        end

        override :sprite_icon
        def sprite_icon
          'issues'
        end

        override :has_pill?
        def has_pill?
          true
        end

        override :pill_count
        def pill_count
          strong_memoize(:pill_count) do
            count_service = ::Groups::OpenIssuesCountService
            count = count_service.new(context.group, context.current_user).count

            format_cached_count(count_service, count)
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
            link: issues_group_path(context.group),
            active_routes: { path: 'groups#issues' },
            container_html_options: { aria: { label: _('Issues') } },
            item_id: :issue_list
          )
        end

        def boards_menu_item
          unless can?(context.current_user, :read_group_boards, context.group)
            return ::Sidebars::NilMenuItem.new(item_id: :boards)
          end

          title = context.group.multiple_issue_boards_available? ? s_('IssueBoards|Boards') : s_('IssueBoards|Board')

          ::Sidebars::MenuItem.new(
            title: title,
            link: group_boards_path(context.group),
            active_routes: { path: %w[boards#index boards#show] },
            item_id: :boards
          )
        end

        def milestones_menu_item
          unless can?(context.current_user, :read_group_milestones, context.group)
            return ::Sidebars::NilMenuItem.new(item_id: :milestones)
          end

          ::Sidebars::MenuItem.new(
            title: _('Milestones'),
            link: group_milestones_path(context.group),
            active_routes: { path: 'milestones#index' },
            item_id: :milestones
          )
        end
      end
    end
  end
end

Sidebars::Groups::Menus::IssuesMenu.prepend_mod_with('Sidebars::Groups::Menus::IssuesMenu')
