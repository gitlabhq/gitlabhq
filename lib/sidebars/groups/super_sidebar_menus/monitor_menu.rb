# frozen_string_literal: true

module Sidebars
  module Groups
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

        override :configure_menu_items
        def configure_menu_items
          [
            :explore,
            :datasources
          ].each { |id| add_item(::Sidebars::NilMenuItem.new(item_id: id)) }
        end
      end
    end
  end
end
