# frozen_string_literal: true

module QA
  module Page
    module Group
      module SubMenus
        module Common
          def self.included(base)
            base.class_eval do
              view 'app/views/layouts/nav/sidebar/_group.html.haml' do
                element :group_sidebar
              end
            end
          end

          def hover_element(element)
            within_sidebar do
              find_element(element).hover
              yield
            end
          end

          def within_sidebar
            within_element(:group_sidebar) do
              yield
            end
          end

          def within_submenu(element)
            within_element(element) do
              yield
            end
          end
        end
      end
    end
  end
end
