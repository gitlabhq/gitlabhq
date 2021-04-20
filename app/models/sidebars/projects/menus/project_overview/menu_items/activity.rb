# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module ProjectOverview
        module MenuItems
          class Activity < ::Sidebars::MenuItem
            override :link
            def link
              activity_project_path(context.project)
            end

            override :extra_container_html_options
            def extra_container_html_options
              {
                class: 'shortcuts-project-activity'
              }
            end

            override :active_routes
            def active_routes
              { path: 'projects#activity' }
            end

            override :title
            def title
              _('Activity')
            end
          end
        end
      end
    end
  end
end
