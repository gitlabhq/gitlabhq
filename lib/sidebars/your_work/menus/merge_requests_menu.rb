# frozen_string_literal: true

module Sidebars
  module YourWork
    module Menus
      class MergeRequestsMenu < ::Sidebars::Menu
        include IssuablesHelper
        include MergeRequestsHelper

        override :link
        def link
          unless context.current_user.merge_request_dashboard_enabled?
            assignee_username = @context.current_user.username
          end

          merge_requests_dashboard_path(assignee_username: assignee_username)
        end

        override :title
        def title
          _('Merge requests')
        end

        override :sprite_icon
        def sprite_icon
          'merge-request'
        end

        override :configure_menu_items
        def configure_menu_items
          return false if context.current_user.merge_request_dashboard_enabled?

          add_item(assigned_mrs_menu_item)
          add_item(reviewer_mrs_menu_item)

          true
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
          user_merge_requests_counts[:total]
        end

        private

        def assigned_mrs_menu_item
          link = merge_requests_dashboard_path(assignee_username: context.current_user.username)

          ::Sidebars::MenuItem.new(
            title: _('Assigned'),
            link: link,
            active_routes: { page: link },
            has_pill: true,
            pill_count: user_merge_requests_counts[:assigned],
            item_id: :merge_requests_assigned
          )
        end

        def reviewer_mrs_menu_item
          link = merge_requests_dashboard_path(reviewer_username: context.current_user.username)

          ::Sidebars::MenuItem.new(
            title: _('Review requests'),
            link: link,
            active_routes: { page: link },
            has_pill: true,
            pill_count: user_merge_requests_counts[:review_requested],
            item_id: :merge_requests_to_review
          )
        end
      end
    end
  end
end
