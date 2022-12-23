# frozen_string_literal: true

module Sidebars
  module YourWork
    module Menus
      class ProjectsMenu < ::Sidebars::Menu
        override :link
        def link
          dashboard_projects_path
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
          !!context.current_user
        end

        override :active_routes
        def active_routes
          { controller: ['root', 'projects', 'dashboard/projects'] }
        end
      end
    end
  end
end
