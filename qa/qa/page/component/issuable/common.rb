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

            base.view 'app/assets/javascripts/related_issues/components/add_issuable_form.vue' do
              element 'add-issue-button'
            end

            base.view 'app/assets/javascripts/related_issues/components/related_issuable_input.vue' do
              element 'add-issue-field'
            end
          end
        end
      end
    end
  end
end
