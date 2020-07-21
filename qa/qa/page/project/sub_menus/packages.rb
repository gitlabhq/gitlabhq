# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module Packages
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.class_eval do
              view 'app/views/layouts/nav/sidebar/_project_packages_link.html.haml' do
                element :packages_link
              end
            end
          end

          def click_packages_link
            within_sidebar do
              click_element :packages_link
            end
          end
        end
      end
    end
  end
end
