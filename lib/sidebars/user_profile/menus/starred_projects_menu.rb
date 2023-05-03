# frozen_string_literal: true

module Sidebars
  module UserProfile
    module Menus
      class StarredProjectsMenu < ::Sidebars::UserProfile::BaseMenu
        override :link
        def link
          user_starred_projects_path(context.container)
        end

        override :title
        def title
          s_('UserProfile|Starred projects')
        end

        override :sprite_icon
        def sprite_icon
          'star-o'
        end

        override :active_routes
        def active_routes
          { path: 'users#starred' }
        end
      end
    end
  end
end
