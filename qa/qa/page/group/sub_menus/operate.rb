# frozen_string_literal: true

module QA
  module Page
    module Group
      module SubMenus
        module Operate
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.class_eval do
              include QA::Page::SubMenus::Operate
            end
          end
        end
      end
    end
  end
end
