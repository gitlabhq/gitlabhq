# frozen_string_literal: true

module QA
  module Page
    module SubMenus
      module Manage
        extend QA::Page::PageConcern

        def go_to_activity
          open_manage_submenu('Activity')
        end

        def go_to_members
          open_manage_submenu('Members')
        end

        def go_to_labels
          open_manage_submenu('Labels')
        end

        private

        def open_manage_submenu(sub_menu)
          open_submenu('Manage', sub_menu)
        end
      end
    end
  end
end
