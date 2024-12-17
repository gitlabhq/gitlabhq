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
          'merge-request'
        end

        override :render?
        def render?
          can?(context.current_user, :read_group_merge_requests, context.group)
        end

        override :has_pill?
        def has_pill?
          true
        end

        override :pill_count_field
        def pill_count_field
          'openMergeRequestsCount'
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

        override :serialize_as_menu_item_args
        def serialize_as_menu_item_args
          super.merge({
            pill_count: pill_count,
            pill_count_field: pill_count_field,
            has_pill: has_pill?,
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::CodeMenu,
            item_id: :group_merge_request_list
          })
        end
      end
    end
  end
end
