# frozen_string_literal: true

module Sidebars
  module Groups
    module SuperSidebarMenus
      class CodeMenu < ::Sidebars::Menu
        override :title
        def title
          s_('Navigation|Code')
        end

        override :sprite_icon
        def sprite_icon
          'code'
        end

        override :configure_menu_items
        def configure_menu_items
          [
            :group_merge_request_list
          ].each { |id| add_item(::Sidebars::NilMenuItem.new(item_id: id)) }
        end
      end
    end
  end
end
