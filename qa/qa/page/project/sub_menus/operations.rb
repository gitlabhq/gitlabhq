# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module Operations
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.class_eval do
              include QA::Page::Project::SubMenus::Common
            end
          end

          def go_to_operations_environments
            hover_operations do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Environments')
              end
            end
          end

          def go_to_operations_metrics
            hover_operations do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Metrics')
              end
            end
          end

          def go_to_operations_kubernetes
            hover_operations do
              within_submenu do
                click_link('Kubernetes')
              end
            end
          end

          def go_to_operations_incidents
            hover_operations do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Incidents')
              end
            end
          end

          private

          def hover_operations
            within_sidebar do
              scroll_to_element(:sidebar_menu_link, menu_item: 'Operations')
              find_element(:sidebar_menu_link, menu_item: 'Operations').hover

              yield
            end
          end
        end
      end
    end
  end
end
