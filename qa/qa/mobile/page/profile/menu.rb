# frozen_string_literal: true

module QA
  module Mobile
    module Page
      module Profile
        module Menu
          extend QA::Page::PageConcern

          def self.prepended(base)
            super

            base.class_eval do
              prepend QA::Mobile::Page::Main::Menu
            end
          end

          def within_sidebar
            open_mobile_nav_sidebar
            super
          end
        end
      end
    end
  end
end
