# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module Common
          extend QA::Page::PageConcern
          include QA::Page::SubMenus::Common

          private

          def sidebar_element
            :project_sidebar
          end
        end
      end
    end
  end
end
