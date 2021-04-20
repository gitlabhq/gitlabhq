# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module Repository
        module MenuItems
          class Files < ::Sidebars::MenuItem
            override :link
            def link
              project_tree_path(context.project, context.current_ref)
            end

            override :active_routes
            def active_routes
              { controller: %w[tree blob blame edit_tree new_tree find_file] }
            end

            override :title
            def title
              _('Files')
            end
          end
        end
      end
    end
  end
end
