# frozen_string_literal: true

module QA
  module Page
    module Group
      module SubMenus
        module Common
          extend QA::Page::PageConcern
          include QA::Page::SubMenus::Common

          def self.included(base)
            super

            base.class_eval do
              view 'app/views/shared/nav/_sidebar.html.haml' do
                element :group_sidebar, 'qa_selector: sidebar_qa_selector(sidebar.container)' # rubocop:disable QA/ElementWithPattern
              end
            end
          end

          private

          def sidebar_element
            :group_sidebar
          end
        end
      end
    end
  end
end
