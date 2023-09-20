# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module Common
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.class_eval do
              include QA::Page::SubMenus::Common

              view 'app/views/layouts/nav/_top_bar.html.haml' do
                element :toggle_mobile_nav_button
              end
            end
          end
        end
      end
    end
  end
end
