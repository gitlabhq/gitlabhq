# frozen_string_literal: true

module Sidebars
  module Projects
    module SuperSidebarMenus
      class ManageMenu < ::Sidebars::Menu
        override :title
        def title
          s_('Navigation|Manage')
        end

        override :sprite_icon
        def sprite_icon
          'users'
        end
      end
    end
  end
end
