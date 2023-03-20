# frozen_string_literal: true

module Sidebars
  module UserSettings
    module Menus
      class PreferencesMenu < ::Sidebars::Menu
        include ::Sidebars::Concerns::RenderIfLoggedIn

        override :link
        def link
          profile_preferences_path
        end

        override :title
        def title
          _('Preferences')
        end

        override :sprite_icon
        def sprite_icon
          'preferences'
        end

        override :active_routes
        def active_routes
          { controller: :preferences }
        end
      end
    end
  end
end
