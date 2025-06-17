# frozen_string_literal: true

module Sidebars # rubocop: disable Gitlab/BoundedContexts -- unknown
  module Explore
    module Menus
      class AiCatalogMenu < ::Sidebars::Menu
        override :link
        def link
          explore_ai_catalog_path
        end

        override :title
        def title
          s_('AI|AI Catalog')
        end

        override :sprite_icon
        def sprite_icon
          'tanuki-ai'
        end

        override :render?
        def render?
          Feature.enabled?(:global_ai_catalog, current_user)
        end

        override :active_routes
        def active_routes
          { controller: ['explore/ai_catalog'] }
        end
      end
    end
  end
end
