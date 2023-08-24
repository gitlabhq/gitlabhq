# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module CreateNewMenu
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.class_eval do
              include QA::Page::SubMenus::CreateNewMenu
            end
          end

          def go_to_new_issue
            within_new_item_menu do
              click_element(:create_menu_item, create_menu_item: 'new_issue')
            end
          end

          def go_to_new_merge_request
            within_new_item_menu do
              click_element(:create_menu_item, create_menu_item: 'new_mr')
            end
          end

          def go_to_new_project_snippet
            within_new_item_menu do
              click_element(:create_menu_item, create_menu_item: 'new_snippet')
            end
          end

          def go_to_invite_members
            within_new_item_menu do
              click_element(:create_menu_item, create_menu_item: 'invite')
            end
          end
        end
      end
    end
  end
end
