# frozen_string_literal: true

module Sidebars
  module Groups
    module Menus
      class MergeRequestsMenu < ::Sidebars::Menu
        include Gitlab::Utils::StrongMemoize

        override :link
        def link
          merge_requests_group_path(context.group)
        end

        override :title
        def title
          _('Merge requests')
        end

        override :sprite_icon
        def sprite_icon
          'git-merge'
        end

        override :render?
        def render?
          can?(context.current_user, :read_group_merge_requests, context.group)
        end

        override :has_pill?
        def has_pill?
          true
        end

        override :pill_count
        def pill_count
          strong_memoize(:pill_count) do
            count_service = ::Groups::MergeRequestsCountService
            count = count_service.new(context.group, context.current_user).count

            format_cached_count(count_service, count)
          end
        end

        override :pill_html_options
        def pill_html_options
          {
            class: 'merge_counter js-merge-counter'
          }
        end

        override :active_routes
        def active_routes
          { path: 'groups#merge_requests' }
        end
      end
    end
  end
end
