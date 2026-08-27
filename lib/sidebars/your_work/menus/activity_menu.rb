# frozen_string_literal: true

module Sidebars
  module YourWork
    module Menus
      class ActivityMenu < ::Sidebars::Menu
        override :link
        def link
          activity_dashboard_path(organization_path: nil)
        end

        override :title
        def title
          _('Activity')
        end

        override :sprite_icon
        def sprite_icon
          'history'
        end

        override :render?
        def render?
          !!context.current_user
        end

        override :active_routes
        def active_routes
          { path: 'dashboard#activity' }
        end
      end
    end
  end
end
