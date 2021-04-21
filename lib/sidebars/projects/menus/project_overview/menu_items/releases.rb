# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module ProjectOverview
        module MenuItems
          class Releases < ::Sidebars::MenuItem
            override :link
            def link
              project_releases_path(context.project)
            end

            override :extra_container_html_options
            def extra_container_html_options
              {
                class: 'shortcuts-project-releases'
              }
            end

            override :render?
            def render?
              can?(context.current_user, :read_release, context.project) && !context.project.empty_repo?
            end

            override :active_routes
            def active_routes
              { controller: :releases }
            end

            override :title
            def title
              _('Releases')
            end
          end
        end
      end
    end
  end
end
