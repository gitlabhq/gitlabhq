# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module Common
          extend QA::Page::PageConcern
          include QA::Page::SubMenus::Common

          def self.included(base)
            super

            base.class_eval do
              view 'app/views/shared/nav/_sidebar_menu_item.html.haml' do
                element :sidebar_menu_item_link
              end

              view 'app/views/shared/nav/_sidebar_menu.html.haml' do
                element :sidebar_menu_link
              end
            end
          end

          private

          def sidebar_element
            :project_sidebar
          end
        end
      end
    end
  end
end
