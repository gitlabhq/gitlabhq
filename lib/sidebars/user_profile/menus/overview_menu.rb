# frozen_string_literal: true

module Sidebars
  module UserProfile
    module Menus
      class OverviewMenu < ::Sidebars::UserProfile::BaseMenu
        override :link
        def link
          user_path(context.container)
        end

        override :title
        def title
          s_('UserProfile|Overview')
        end

        override :sprite_icon
        def sprite_icon
          'overview'
        end

        override :active_routes
        def active_routes
          { path: 'users#show' }
        end
      end
    end
  end
end
