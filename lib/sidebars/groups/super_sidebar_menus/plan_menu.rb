# frozen_string_literal: true

module Sidebars
  module Groups
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
            :group_issue_list,
            :group_epic_list,
            :issue_boards,
            :epic_boards,
            :roadmap,
            :milestones,
            :iterations,
            :group_wiki,
            :crm_contacts
          ].each { |id| add_item(::Sidebars::NilMenuItem.new(item_id: id)) }
        end
      end
    end
  end
end
