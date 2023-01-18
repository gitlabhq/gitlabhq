# frozen_string_literal: true

module Sidebars
  module YourWork
    module Menus
      class MergeRequestsMenu < ::Sidebars::Menu
        include Gitlab::Utils::StrongMemoize

        override :link
        def link
          merge_requests_dashboard_path(assignee_username: @context.current_user.username)
        end

        override :title
        def title
          _('Merge requests')
        end

        override :sprite_icon
        def sprite_icon
          'merge-request'
        end

        override :render?
        def render?
          !!context.current_user
        end

        override :active_routes
        def active_routes
          { path: 'dashboard#merge_requests' }
        end

        override :has_pill?
        def has_pill?
          pill_count > 0
        end

        override :pill_count
        def pill_count
          context.current_user.assigned_open_merge_requests_count
        end
        strong_memoize_attr :pill_count
      end
    end
  end
end
