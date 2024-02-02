# frozen_string_literal: true

module Sidebars
  module UserSettings
    module Menus
      class ProfileMenu < ::Sidebars::Menu
        include ::Sidebars::Concerns::RenderIfLoggedIn

        override :link
        def link
          user_settings_profile_path
        end

        override :title
        def title
          _('Profile')
        end

        override :sprite_icon
        def sprite_icon
          'profile'
        end

        override :active_routes
        def active_routes
          { path: 'user_settings/profiles#show' }
        end
      end
    end
  end
end
