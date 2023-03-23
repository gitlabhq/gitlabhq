# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module SuperSidebar
          module Common
            private

            def open_submenu(parent_menu_name, parent_section_id, sub_menu)
              click_element(:sidebar_menu_link, menu_item: parent_menu_name)

              # TODO: it's not possible to add qa-selectors to sub-menu container
              within(parent_section_id) do
                click_element(:sidebar_menu_link, menu_item: sub_menu)
              end
            end
          end
        end
      end
    end
  end
end
