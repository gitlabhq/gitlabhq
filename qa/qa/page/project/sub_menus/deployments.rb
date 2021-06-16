# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module Deployments
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.class_eval do
              include QA::Page::Project::SubMenus::Common
            end
          end

          def go_to_deployments_environments
            hover_deployments do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Environments')
              end
            end
          end

          private

          def hover_deployments
            within_sidebar do
              scroll_to_element(:sidebar_menu_link, menu_item: 'Deployments')
              find_element(:sidebar_menu_link, menu_item: 'Deployments').hover

              yield
            end
          end
        end
      end
    end
  end
end
