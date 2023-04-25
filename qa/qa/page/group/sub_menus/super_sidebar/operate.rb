# frozen_string_literal: true

module QA
  module Page
    module Group
      module SubMenus
        module SuperSidebar
          module Operate
            extend QA::Page::PageConcern

            def self.prepended(base)
              super

              base.class_eval do
                include QA::Page::SubMenus::SuperSidebar::Operate
              end
            end
          end
        end
      end
    end
  end
end
