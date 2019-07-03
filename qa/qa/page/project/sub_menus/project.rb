# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module Project
          include Common

          def self.included(base)
            base.class_eval do
              view 'app/views/layouts/nav/sidebar/_project.html.haml' do
                element :link_project
              end
            end
          end

          def click_project
            retry_on_exception do
              within_sidebar do
                click_element(:link_project)
              end
            end
          end
        end
      end
    end
  end
end
