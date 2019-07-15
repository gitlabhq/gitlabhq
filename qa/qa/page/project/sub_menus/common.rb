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
            if has_css?('.fly-out-list')
              within('.fly-out-list') do
                yield
              end
            else
              yield
            end
          end
        end
      end
    end
  end
end
