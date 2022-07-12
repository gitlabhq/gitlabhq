# frozen_string_literal: true

module QA
  module Page
    module Component
      module Issuable
        module Common
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.view 'app/assets/javascripts/vue_shared/issuable/show/components/issuable_title.vue' do
              element :title_content, required: true
            end
          end
        end
      end
    end
  end
end
