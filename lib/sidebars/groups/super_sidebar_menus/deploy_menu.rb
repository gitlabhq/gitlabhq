# frozen_string_literal: true

module Sidebars
  module Groups
    module SuperSidebarMenus
      class DeployMenu < ::Sidebars::Menu
        override :title
        def title
          s_('Navigation|Deploy')
        end

        override :sprite_icon
        def sprite_icon
          'deployments'
        end

        override :configure_menu_items
        def configure_menu_items
          [
            :packages_registry,
            :container_registry
          ].each { |id| add_item(::Sidebars::NilMenuItem.new(item_id: id)) }
        end
      end
    end
  end
end
