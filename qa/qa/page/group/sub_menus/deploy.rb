# frozen_string_literal: true

module QA
  module Page
    module Group
      module SubMenus
        module Deploy
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.class_eval do
              include QA::Page::SubMenus::Deploy
            end
          end
        end
      end
    end
  end
end
