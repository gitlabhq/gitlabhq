# frozen_string_literal: true

module Sidebars
  module UserProfile
    module Menus
      class ContributedProjectsMenu < ::Sidebars::UserProfile::BaseMenu
        override :link
        def link
          user_contributed_projects_path(context.container)
        end

        override :title
        def title
          s_('UserProfile|Contributed projects')
        end

        override :sprite_icon
        def sprite_icon
          'project'
        end

        override :active_routes
        def active_routes
          { path: 'users#contributed' }
        end
      end
    end
  end
end
