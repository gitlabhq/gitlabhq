# frozen_string_literal: true

module Sidebars
  module UserProfile
    module Menus
      class ActivityMenu < ::Sidebars::UserProfile::BaseMenu
        override :link
        def link
          user_activity_path(context.container)
        end

        override :title
        def title
          s_('UserProfile|Activity')
        end

        override :sprite_icon
        def sprite_icon
          'history'
        end

        override :active_routes
        def active_routes
          { path: 'users#activity' }
        end
      end
    end
  end
end
