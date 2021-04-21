# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module LearnGitlab
        class Menu < ::Sidebars::Menu
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

          override :extra_container_html_options
          def nav_link_html_options
            { class: 'home' }
          end

          override :sprite_icon
          def sprite_icon
            'home'
          end

          override :render?
          def render?
            context.learn_gitlab_experiment_enabled
          end
        end
      end
    end
  end
end
