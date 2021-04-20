# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module Repository
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.class_eval do
              include QA::Page::Project::SubMenus::Common

              view 'app/views/shared/nav/_sidebar_menu_item.html.haml' do
                element :sidebar_menu_item_link
              end

              view 'app/views/shared/nav/_sidebar_menu.html.haml' do
                element :sidebar_menu_link
              end
            end
          end

          def click_repository
            within_sidebar do
              click_element(:sidebar_menu_link, menu_item: 'Repository')
            end
          end

          def go_to_repository_branches
            hover_repository do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Branches')
              end
            end
          end

          def go_to_repository_tags
            hover_repository do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Tags')
              end
            end
          end

          private

          def hover_repository
            within_sidebar do
              find_element(:sidebar_menu_link, menu_item: 'Repository').hover

              yield
            end
          end
        end
      end
    end
  end
end
