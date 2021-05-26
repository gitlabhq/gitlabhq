# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class ScopeMenu < ::Sidebars::Menu
        override :link
        def link
          project_path(context.project)
        end

        override :title
        def title
          context.project.name
        end

        override :active_routes
        def active_routes
          { path: 'projects#show' }
        end

        override :extra_container_html_options
        def extra_container_html_options
          return {} if Feature.disabled?(:sidebar_refactor, context.current_user, default_enabled: :yaml)

          {
            class: 'shortcuts-project rspec-project-link'
          }
        end

        override :nav_link_html_options
        def nav_link_html_options
          return {} if Feature.disabled?(:sidebar_refactor, context.current_user, default_enabled: :yaml)

          { class: 'context-header' }
        end
      end
    end
  end
end
