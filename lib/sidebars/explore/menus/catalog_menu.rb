# frozen_string_literal: true

module Sidebars
  module Explore
    module Menus
      class CatalogMenu < ::Sidebars::Menu
        override :link
        def link
          explore_catalog_index_path
        end

        override :title
        def title
          _('CI/CD Catalog')
        end

        override :sprite_icon
        def sprite_icon
          'catalog-checkmark'
        end

        override :render?
        def render?
          true
        end

        override :active_routes
        def active_routes
          { controller: ['explore/catalog'] }
        end
      end
    end
  end
end
