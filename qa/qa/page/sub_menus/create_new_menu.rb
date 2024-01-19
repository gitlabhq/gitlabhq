# frozen_string_literal: true

module QA
  module Page
    module SubMenus
      module CreateNewMenu
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.class_eval do
            include QA::Page::SubMenus::Common

            view 'app/helpers/sidebars_helper.rb' do
              element :create_menu_item
            end
          end
        end

        def go_to_create_project
          within_new_item_menu do
            click_element(:create_menu_item, create_menu_item: 'general_new_project')
          end
        end

        def go_to_create_snippet
          within_new_item_menu do
            click_element(:create_menu_item, create_menu_item: 'general_new_snippet')
          end
        end

        def go_to_create_group
          within_new_item_menu do
            click_element(:create_menu_item, create_menu_item: 'general_new_group')
          end
        end

        def go_to_create_organization
          within_new_item_menu do
            click_element(:create_menu_item, create_menu_item: 'general_new_organization')
          end
        end
      end
    end
  end
end
