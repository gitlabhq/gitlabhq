# frozen_string_literal: true

module Sidebars
  module UserProfile
    module Menus
      class PersonalProjectsMenu < ::Sidebars::UserProfile::BaseMenu
        override :link
        def link
          user_projects_path(context.container)
        end

        override :title
        def title
          s_('UserProfile|Personal projects')
        end

        override :sprite_icon
        def sprite_icon
          'project'
        end

        override :active_routes
        def active_routes
          { path: 'users#projects' }
        end
      end
    end
  end
end
