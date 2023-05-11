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

        override :configure_menu_items
        def configure_menu_items
          [
            :activity,
            :members,
            :labels
          ].each { |id| add_item(::Sidebars::NilMenuItem.new(item_id: id)) }
        end
      end
    end
  end
end
