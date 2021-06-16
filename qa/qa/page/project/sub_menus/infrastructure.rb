# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module Infrastructure
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.class_eval do
              include QA::Page::Project::SubMenus::Common
            end
          end

          def go_to_infrastructure_kubernetes
            hover_infrastructure do
              within_submenu do
                click_link('Kubernetes clusters')
              end
            end
          end

          private

          def hover_infrastructure
            within_sidebar do
              scroll_to_element(:sidebar_menu_link, menu_item: 'Infrastructure')
              find_element(:sidebar_menu_link, menu_item: 'Infrastructure').hover

              yield
            end
          end
        end
      end
    end
  end
end
