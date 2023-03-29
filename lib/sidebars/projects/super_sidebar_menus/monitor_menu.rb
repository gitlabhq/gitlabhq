# frozen_string_literal: true

module Sidebars
  module Projects
    module SuperSidebarMenus
      class MonitorMenu < ::Sidebars::Menu
        override :title
        def title
          s_('Navigation|Monitor')
        end

        override :sprite_icon
        def sprite_icon
          'monitor'
        end
      end
    end
  end
end
