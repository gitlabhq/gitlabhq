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

            base.view 'app/assets/javascripts/vue_shared/issuable/show/components/issuable_header.vue' do
              element 'issue-author'
            end
          end

          def has_author?(author_username)
            within_element('issue-author') do
              has_text?(author_username)
            end
          end
        end
      end
    end
  end
end
