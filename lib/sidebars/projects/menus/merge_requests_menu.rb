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

        override :title_html_options
        def title_html_options
          {
            id: 'js-onboarding-mr-link'
          }
        end

        override :sprite_icon
        def sprite_icon
          'git-merge'
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

        override :pill_count
        def pill_count
          @pill_count ||= context.project.open_merge_requests_count
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
            { controller: :merge_requests }
          else
            { controller: [:merge_requests, :milestones] }
          end
        end
      end
    end
  end
end
