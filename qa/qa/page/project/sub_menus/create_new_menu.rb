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

              view 'app/assets/javascripts/work_items/components/create_work_item_modal.vue' do
                element 'new-work-item-modal-link'
              end
            end
          end

          def go_to_new_issue
            within_new_item_menu do
              link = has_element?(:create_menu_item, create_menu_item: 'new_work_item') ? 'new_work_item' : 'new_issue'
              click_element(:create_menu_item, create_menu_item: link)
            end

            # Click the "Open in full page" link if modal appears
            click_element('new-work-item-modal-link') if has_element?('new-work-item-modal-link')
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
