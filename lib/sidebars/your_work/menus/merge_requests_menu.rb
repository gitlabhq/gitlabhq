# frozen_string_literal: true

module Sidebars
  module YourWork
    module Menus
      class MergeRequestsMenu < ::Sidebars::Menu
        include IssuablesHelper
        include MergeRequestsHelper

        override :link
        def link
          merge_requests_dashboard_path
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
          false
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
          true
        end

        override :pill_count_field
        def pill_count_field
          "total_merge_requests"
        end
      end
    end
  end
end
