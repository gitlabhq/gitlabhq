# frozen_string_literal: true

module QA
  module Mobile
    module Page
      module SubMenus
        module Common
          def open_mobile_nav_sidebar
            if has_element?(:project_sidebar, visible: false)
              Support::Retrier.retry_until do
                click_element(:toggle_mobile_nav_button)
                has_element?(:project_sidebar, visible: true)
              end
            end
          end

          def within_sidebar
            wait_for_requests

            open_mobile_nav_sidebar

            super
          end
        end
      end
    end
  end
end
