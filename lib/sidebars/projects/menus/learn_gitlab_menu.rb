# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class LearnGitlabMenu < ::Sidebars::Menu
        include Gitlab::Utils::StrongMemoize

        override :link
        def link
          project_learn_gitlab_path(context.project)
        end

        override :active_routes
        def active_routes
          { controller: :learn_gitlab }
        end

        override :title
        def title
          _('Learn GitLab')
        end

        override :has_pill?
        def has_pill?
          context.learn_gitlab_enabled
        end

        override :pill_count
        def pill_count
          strong_memoize(:pill_count) do
            percentage = LearnGitlab::Onboarding.new(
              context.project.namespace,
              context.current_user
            ).completed_percentage

            "#{percentage}%"
          end
        end

        override :extra_nav_link_html_options
        def extra_nav_link_html_options
          {
            class: 'home',
            data: {
              track_label: 'learn_gitlab'
            }
          }
        end

        override :sprite_icon
        def sprite_icon
          'bulb'
        end

        override :render?
        def render?
          context.learn_gitlab_enabled
        end
      end
    end
  end
end
