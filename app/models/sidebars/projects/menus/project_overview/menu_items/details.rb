# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module ProjectOverview
        module MenuItems
          class Details < ::Sidebars::MenuItem
            override :link
            def link
              project_path(context.project)
            end

            override :extra_container_html_options
            def extra_container_html_options
              {
                aria: { label: _('Project details') },
                class: 'shortcuts-project'
              }
            end

            override :active_routes
            def active_routes
              { path: 'projects#show' }
            end

            override :title
            def title
              _('Details')
            end
          end
        end
      end
    end
  end
end
