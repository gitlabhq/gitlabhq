# frozen_string_literal: true

module Sidebars
  module UserSettings
    module Menus
      class AuthenticationLogMenu < ::Sidebars::Menu
        include ::Sidebars::Concerns::RenderIfLoggedIn

        override :link
        def link
          user_settings_authentication_log_path
        end

        override :title
        def title
          _('Authentication Log')
        end

        override :sprite_icon
        def sprite_icon
          'log'
        end

        override :active_routes
        def active_routes
          { path: 'user_settings#authentication_log' }
        end
      end
    end
  end
end
