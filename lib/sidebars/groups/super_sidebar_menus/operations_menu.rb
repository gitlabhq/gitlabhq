# frozen_string_literal: true

module Sidebars
  module Groups
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
            :dependency_proxy,
            :group_kubernetes_clusters
          ].each { |id| add_item(::Sidebars::NilMenuItem.new(item_id: id)) }
        end
      end
    end
  end
end
