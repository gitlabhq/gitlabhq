# frozen_string_literal: true

module Sidebars
  module UserSettings
    module Menus
      class ApplicationsMenu < ::Sidebars::Menu
        include ::Sidebars::Concerns::RenderIfLoggedIn

        override :link
        def link
          user_settings_applications_path
        end

        override :title
        def title
          _('Applications')
        end

        override :sprite_icon
        def sprite_icon
          'applications'
        end

        override :active_routes
        def active_routes
          { controller: 'oauth/applications' }
        end
      end
    end
  end
end
