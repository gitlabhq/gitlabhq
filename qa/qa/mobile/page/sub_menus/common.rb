# frozen_string_literal: true

module QA
  module Mobile
    module Page
      module SubMenus
        module Common
          def open_mobile_nav_sidebar
            unless has_css?('.sidebar-expanded-mobile')
              Support::Retrier.retry_until do
                click_element(:toggle_mobile_nav_button)
                has_css?('.sidebar-expanded-mobile')
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
