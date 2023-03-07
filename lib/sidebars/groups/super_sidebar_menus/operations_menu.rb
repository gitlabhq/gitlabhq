# frozen_string_literal: true

module Sidebars
  module Groups
    module SuperSidebarMenus
      class OperationsMenu < ::Sidebars::Menu
        override :title
        def title
          _('Operations')
        end

        override :sprite_icon
        def sprite_icon
          'deployments'
        end
      end
    end
  end
end
