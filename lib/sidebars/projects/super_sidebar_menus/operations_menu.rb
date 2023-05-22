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
          'cloud-pod'
        end

        override :configure_menu_items
        def configure_menu_items
          [
            :environments,
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
