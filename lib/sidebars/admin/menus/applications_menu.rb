# frozen_string_literal: true

module Sidebars
  module Admin
    module Menus
      class ApplicationsMenu < ::Sidebars::Admin::BaseMenu
        override :link
        def link
          admin_applications_path
        end

        override :title
        def title
          s_('Admin|Applications')
        end

        override :sprite_icon
        def sprite_icon
          'applications'
        end

        override :active_routes
        def active_routes
          { controller: :applications }
        end
      end
    end
  end
end
