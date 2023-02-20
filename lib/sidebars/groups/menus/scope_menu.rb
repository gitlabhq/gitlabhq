# frozen_string_literal: true

module Sidebars
  module Groups
    module Menus
      class ScopeMenu < ::Sidebars::Menu
        override :link
        def link
          group_path(context.group)
        end

        override :title
        def title
          context.group.name
        end

        override :active_routes
        def active_routes
          { path: %w[groups#show groups#details groups#new projects#new] }
        end

        override :extra_nav_link_html_options
        def extra_nav_link_html_options
          {
            class: 'context-header has-tooltip',
            title: context.group.name,
            data: { container: 'body', placement: 'right' }
          }
        end

        override :render?
        def render?
          true
        end
      end
    end
  end
end
