# frozen_string_literal: true

module Sidebars
  module Projects
    module SuperSidebarMenus
      class OperationsMenu < ::Sidebars::Menu
        override :title
        def title
          s_('Navigation|Operate')
        end

        override :sprite_icon
        def sprite_icon
          'deployments'
        end

        override :configure_menu_items
        def configure_menu_items
          [
            :packages_registry,
            :container_registry,
            :kubernetes,
            :terraform_states,
            :infrastructure_registry,
            :google_cloud,
            :aws
          ].each { |id| add_item(::Sidebars::NilMenuItem.new(item_id: id)) }
        end
      end
    end
  end
end
