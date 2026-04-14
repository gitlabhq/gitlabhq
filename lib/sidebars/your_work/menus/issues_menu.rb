# frozen_string_literal: true

module Sidebars
  module YourWork
    module Menus
      class IssuesMenu < ::Sidebars::Menu
        include Gitlab::Utils::StrongMemoize

        override :link
        def link
          work_items_dashboard_path(assignee_username: @context.current_user.username)
        end

        override :title
        def title
          _('Work items')
        end

        override :sprite_icon
        def sprite_icon
          'work-items'
        end

        override :render?
        def render?
          !!context.current_user
        end

        override :active_routes
        def active_routes
          { path: %w[dashboard#issues dashboard#work_items] }
        end

        override :has_pill?
        def has_pill?
          true
        end

        override :pill_count_field
        def pill_count_field
          "assigned_issues"
        end
      end
    end
  end
end
