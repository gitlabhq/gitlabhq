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
          {
            class: 'shortcuts-project rspec-project-link'
          }
        end

        override :extra_nav_link_html_options
        def extra_nav_link_html_options
          { class: 'context-header' }
        end

        override :render?
        def render?
          true
        end
      end
    end
  end
end
