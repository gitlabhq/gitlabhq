# frozen_string_literal: true

module Sidebars
  module Explore
    module Menus
      class SnippetsMenu < ::Sidebars::Menu
        override :link
        def link
          explore_snippets_path
        end

        override :title
        def title
          _('Snippets')
        end

        override :sprite_icon
        def sprite_icon
          'snippet'
        end

        override :render?
        def render?
          true
        end

        override :active_routes
        def active_routes
          { controller: ['explore/snippets'] }
        end
      end
    end
  end
end
