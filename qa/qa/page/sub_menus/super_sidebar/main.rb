# frozen_string_literal: true

module QA
  module Page
    module SubMenus
      module SuperSidebar
        module Main
          extend QA::Page::PageConcern

          def go_to_issues
            click_element(:nav_item_link, submenu_item: 'Issues')
          end

          def go_to_merge_requests
            click_element(:nav_item_link, submenu_item: 'Merge requests')
          end
        end
      end
    end
  end
end
