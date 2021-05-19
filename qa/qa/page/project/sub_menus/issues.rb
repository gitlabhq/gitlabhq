# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module Issues
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.class_eval do
              include QA::Page::Project::SubMenus::Common
            end
          end

          def click_issues
            within_sidebar do
              click_element(:sidebar_menu_link, menu_item: 'Issues')
            end
          end

          def click_milestones
            within_sidebar do
              click_element(:sidebar_menu_item_link, menu_item: 'Milestones')
            end
          end

          def go_to_boards
            hover_issues do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Boards')
              end
            end
          end

          def go_to_labels
            hover_issues do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Labels')
              end
            end
          end

          def go_to_milestones
            hover_issues do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Milestones')
              end
            end
          end

          private

          def hover_issues
            within_sidebar do
              scroll_to_element(:sidebar_menu_link, menu_item: 'Issues')
              find_element(:sidebar_menu_link, menu_item: 'Issues').hover

              yield
            end
          end
        end
      end
    end
  end
end
