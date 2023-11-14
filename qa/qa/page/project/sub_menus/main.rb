# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module Main
          extend QA::Page::PageConcern

          def click_project
            click_element('nav-item-link', submenu_item: 'project-overview')
          end
        end
      end
    end
  end
end
