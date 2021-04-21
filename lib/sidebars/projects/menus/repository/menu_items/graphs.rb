# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module Repository
        module MenuItems
          class Graphs < ::Sidebars::MenuItem
            override :link
            def link
              project_network_path(context.project, context.current_ref)
            end

            override :active_routes
            def active_routes
              { controller: :network }
            end

            override :title
            def title
              _('Graph')
            end
          end
        end
      end
    end
  end
end
