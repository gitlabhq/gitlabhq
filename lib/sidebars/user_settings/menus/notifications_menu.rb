# frozen_string_literal: true

module Sidebars
  module UserSettings
    module Menus
      class NotificationsMenu < ::Sidebars::Menu
        include ::Sidebars::Concerns::RenderIfLoggedIn

        override :link
        def link
          profile_notifications_path
        end

        override :title
        def title
          _('Notifications')
        end

        override :sprite_icon
        def sprite_icon
          'notifications'
        end

        override :active_routes
        def active_routes
          { controller: :notifications }
        end
      end
    end
  end
end
