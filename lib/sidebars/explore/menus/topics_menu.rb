# frozen_string_literal: true

module Sidebars
  module Explore
    module Menus
      class TopicsMenu < ::Sidebars::Menu
        override :link
        def link
          topics_explore_projects_path
        end

        override :title
        def title
          _('Topics')
        end

        override :sprite_icon
        def sprite_icon
          'labels'
        end

        override :render?
        def render?
          true
        end

        override :active_routes
        def active_routes
          { page: link, path: 'projects#topic' }
        end
      end
    end
  end
end
