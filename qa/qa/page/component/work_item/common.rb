# frozen_string_literal: true

module QA
  module Page
    module Component
      module WorkItem
        module Common
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.view 'app/assets/javascripts/work_items/components/item_title.vue' do
              element 'work-item-title', required: true
            end

            base.view 'app/assets/javascripts/vue_shared/components/markdown/markdown_editor.vue' do
              element 'markdown-editor-form-field'
            end

            base.view 'app/assets/javascripts/work_items/components/work_item_created_updated.vue' do
              element 'work-item-author'
            end
          end

          def has_author?(author_username)
            within_element('work-item-author') do
              has_text?(author_username)
            end
          end
        end
      end
    end
  end
end
