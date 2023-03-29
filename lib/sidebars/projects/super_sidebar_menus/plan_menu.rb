# frozen_string_literal: true

module Sidebars
  module Projects
    module SuperSidebarMenus
      class PlanMenu < ::Sidebars::Menu
        override :title
        def title
          s_('Navigation|Plan')
        end

        override :sprite_icon
        def sprite_icon
          'planning'
        end
      end
    end
  end
end
