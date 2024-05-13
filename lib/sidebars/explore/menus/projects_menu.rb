# frozen_string_literal: true

module Sidebars
  module Explore
    module Menus
      class ProjectsMenu < ::Sidebars::Menu
        override :link
        def link
          starred_explore_projects_path
        end

        override :title
        def title
          _('Projects')
        end

        override :sprite_icon
        def sprite_icon
          'project'
        end

        override :render?
        def render?
          true
        end

        override :active_routes
        def active_routes
          {
            page: [
              link,
              explore_root_path,
              starred_explore_projects_path,
              trending_explore_projects_path,
              explore_projects_path
            ]
          }
        end
      end
    end
  end
end
