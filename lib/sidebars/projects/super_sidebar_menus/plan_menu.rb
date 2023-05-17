# frozen_string_literal: true

module Sidebars
  module Projects
    module SuperSidebarMenus
      class PlanMenu < ::Sidebars::Menu
        override :title
        def title
          s_('Navigation|Plan')
        end

        override :sprite_icon
        def sprite_icon
          'planning'
        end

        override :configure_menu_items
        def configure_menu_items
          [
            :project_issue_list,
            :boards,
            :milestones,
            :iterations,
            :project_wiki,
            :requirements
          ].each { |id| add_item(::Sidebars::NilMenuItem.new(item_id: id)) }
        end
      end
    end
  end
end
