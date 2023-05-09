# frozen_string_literal: true

module Sidebars
  module Projects
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
            :project_merge_request_list,
            :files,
            :branches,
            :commits,
            :tags,
            :graphs,
            :compare,
            :project_snippets,
            :file_locks
          ].each { |id| add_item(::Sidebars::NilMenuItem.new(item_id: id)) }
        end
      end
    end
  end
end
