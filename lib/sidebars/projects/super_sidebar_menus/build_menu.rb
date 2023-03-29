# frozen_string_literal: true

module Sidebars
  module Projects
    module SuperSidebarMenus
      class BuildMenu < ::Sidebars::Menu
        override :title
        def title
          s_('Navigation|Build')
        end

        override :sprite_icon
        def sprite_icon
          'rocket'
        end
      end
    end
  end
end
