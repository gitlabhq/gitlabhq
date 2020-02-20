# frozen_string_literal: true

module QA
  module Page
    module Group
      module SubMenus
        module Common
          include QA::Page::SubMenus::Common

          def self.included(base)
            base.class_eval do
              view 'app/views/layouts/nav/sidebar/_group.html.haml' do
                element :group_sidebar
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
