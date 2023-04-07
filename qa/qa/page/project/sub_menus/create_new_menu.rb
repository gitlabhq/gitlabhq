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
              # TODO: remove this when the super sidebar is enabled by default
              view 'app/helpers/nav/new_dropdown_helper.rb' do
                element :new_issue_link
              end

              view 'app/helpers/sidebars_helper.rb' do
                element :create_menu_item
              end
            end
          end

          def go_to_new_issue
            within_new_item_menu do
              next click_element(:new_issue_link) unless QA::Runtime::Env.super_sidebar_enabled?

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
