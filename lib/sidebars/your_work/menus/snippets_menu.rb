# frozen_string_literal: true

module Sidebars
  module YourWork
    module Menus
      class SnippetsMenu < ::Sidebars::Menu
        override :link
        def link
          dashboard_snippets_path
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
          !!context.current_user
        end

        override :active_routes
        def active_routes
          { controller: :snippets }
        end
      end
    end
  end
end
