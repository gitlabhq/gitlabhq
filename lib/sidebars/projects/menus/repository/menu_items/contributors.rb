# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module Repository
        module MenuItems
          class Contributors < ::Sidebars::MenuItem
            override :link
            def link
              project_graph_path(context.project, context.current_ref)
            end

            override :active_routes
            def active_routes
              { path: 'graphs#show' }
            end

            override :title
            def title
              _('Contributors')
            end
          end
        end
      end
    end
  end
end
