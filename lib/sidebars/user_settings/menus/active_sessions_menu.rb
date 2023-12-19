# frozen_string_literal: true

module Sidebars
  module UserSettings
    module Menus
      class ActiveSessionsMenu < ::Sidebars::Menu
        include ::Sidebars::Concerns::RenderIfLoggedIn

        override :link
        def link
          user_settings_active_sessions_path
        end

        override :title
        def title
          _('Active Sessions')
        end

        override :sprite_icon
        def sprite_icon
          'monitor-lines'
        end

        override :active_routes
        def active_routes
          { controller: :active_sessions }
        end
      end
    end
  end
end
