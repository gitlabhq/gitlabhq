# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module SuperSidebar
          module Main
            extend QA::Page::PageConcern

            def self.included(base)
              super

              base.class_eval do
                include QA::Page::SubMenus::SuperSidebar::Main
              end
            end

            def click_project
              click_element(:nav_item_link, submenu_item: 'Project overview')
            end
          end
        end
      end
    end
  end
end
