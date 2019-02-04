# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module Common
          def within_sidebar
            within('.sidebar-top-level-items') do
              yield
            end
          end

          def within_submenu
            within('.fly-out-list') do
              yield
            end
          end
        end
      end
    end
  end
end
