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

              view 'app/views/layouts/nav/sidebar/_project.html.haml' do
                element :operations_link
                element :operations_environments_link
                element :operations_metrics_link
              end
            end
          end

          def go_to_operations_environments
            hover_operations do
              within_submenu do
                click_element(:operations_environments_link)
              end
            end
          end

          def go_to_operations_metrics
            hover_operations do
              within_submenu do
                click_element(:operations_metrics_link)
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

          private

          def hover_operations
            within_sidebar do
              scroll_to_element(:operations_link)
              find_element(:operations_link).hover

              yield
            end
          end
        end
      end
    end
  end
end
