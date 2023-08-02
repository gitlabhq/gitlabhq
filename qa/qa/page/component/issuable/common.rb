# frozen_string_literal: true

module QA
  module Page
    module Component
      module Issuable
        module Common
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.view 'app/assets/javascripts/issues/show/components/title.vue' do
              element 'issue-title', required: true
            end
          end
        end
      end
    end
  end
end
