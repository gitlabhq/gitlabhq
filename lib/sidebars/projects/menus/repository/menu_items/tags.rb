# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module Repository
        module MenuItems
          class Tags < ::Sidebars::MenuItem
            override :link
            def link
              project_tags_path(context.project)
            end

            override :active_routes
            def active_routes
              { controller: :tags }
            end

            override :title
            def title
              _('Tags')
            end
          end
        end
      end
    end
  end
end
