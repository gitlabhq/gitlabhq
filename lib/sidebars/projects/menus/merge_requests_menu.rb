# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class MergeRequestsMenu < ::Sidebars::Menu
        override :link
        def link
          project_merge_requests_path(context.project)
        end

        override :extra_container_html_options
        def extra_container_html_options
          {
            class: 'shortcuts-merge_requests'
          }
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
          can?(context.current_user, :read_merge_request, context.project) &&
            context.project.repo_exists?
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
          if context.project.issues_enabled?
            { controller: ['projects/merge_requests', :conflicts] }
          else
            { controller: ['projects/merge_requests', :milestones, :conflicts] }
          end
        end

        override :serialize_as_menu_item_args
        def serialize_as_menu_item_args
          super.merge({
            pill_count: pill_count,
            pill_count_field: pill_count_field,
            has_pill: has_pill?,
            super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::CodeMenu,
            item_id: :project_merge_request_list
          })
        end
      end
    end
  end
end
