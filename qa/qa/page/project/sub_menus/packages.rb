# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module Packages
          extend QA::Page::PageConcern

          def click_packages_link
            hover_registry do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Package Registry')
              end
            end
          end

          def go_to_container_registry
            hover_registry do
              within_submenu do
                click_link('Container Registry')
              end
            end
          end

          private

          def hover_registry
            within_sidebar do
              scroll_to_element(:sidebar_menu_link, menu_item: 'Packages & Registries')
              find_element(:sidebar_menu_link, menu_item: 'Packages & Registries').hover

              yield
            end
          end
        end
      end
    end
  end
end
