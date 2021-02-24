# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module Packages
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.class_eval do
              view 'app/views/layouts/nav/sidebar/_project_packages_link.html.haml' do
                element :packages_link
              end
            end
          end

          def click_packages_link
            within_sidebar do
              click_element :packages_link
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
              scroll_to_element(:packages_link)
              find_element(:packages_link).hover

              yield
            end
          end
        end
      end
    end
  end
end
