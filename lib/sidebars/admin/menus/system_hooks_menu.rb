# frozen_string_literal: true

module Sidebars
  module Admin
    module Menus
      class SystemHooksMenu < ::Sidebars::Admin::BaseMenu
        override :link
        def link
          admin_hooks_path
        end

        override :title
        def title
          s_('Webhooks|System hooks')
        end

        override :sprite_icon
        def sprite_icon
          'hook'
        end

        override :active_routes
        def active_routes
          { controller: :hooks }
        end
      end
    end
  end
end
