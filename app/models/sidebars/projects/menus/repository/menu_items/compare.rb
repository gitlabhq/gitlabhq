# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module Repository
        module MenuItems
          class Compare < ::Sidebars::MenuItem
            override :link
            def link
              project_compare_index_path(context.project, from: context.project.repository.root_ref, to: context.current_ref)
            end

            override :active_routes
            def active_routes
              { controller: :compare }
            end

            override :title
            def title
              _('Compare')
            end
          end
        end
      end
    end
  end
end
