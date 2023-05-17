# frozen_string_literal: true

module Sidebars
  module UserProfile
    module Menus
      class SnippetsMenu < ::Sidebars::UserProfile::BaseMenu
        override :link
        def link
          user_snippets_path(context.container)
        end

        override :title
        def title
          s_('UserProfile|Snippets')
        end

        override :sprite_icon
        def sprite_icon
          'snippet'
        end

        override :active_routes
        def active_routes
          { path: 'users#snippets' }
        end
      end
    end
  end
end
