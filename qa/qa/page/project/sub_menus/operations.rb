# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module Operations
          include Page::Project::SubMenus::Common

          def self.included(base)
            base.class_eval do
              view 'app/views/layouts/nav/sidebar/_project.html.haml' do
                element :link_operations
                element :operations_environments_link
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
              scroll_to_element(:link_operations)
              find_element(:link_operations).hover

              yield
            end
          end
        end
      end
    end
  end
end
