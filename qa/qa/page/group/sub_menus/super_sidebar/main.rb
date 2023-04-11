# frozen_string_literal: true

module QA
  module Page
    module Group
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

            def go_to_group_overview
              click_element(:nav_item_link, submenu_item: 'Group overview')
            end
          end
        end
      end
    end
  end
end
