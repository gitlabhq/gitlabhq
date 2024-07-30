# frozen_string_literal: true

module QA
  module Page
    module Component
      module WorkItem
        module Note
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.view 'app/assets/javascripts/notes/components/note_header.vue' do
              element 'system-note-content'
            end

            base.view 'app/assets/javascripts/vue_shared/components/markdown/markdown_editor.vue' do
              element 'markdown-editor-form-field'
            end

            base.view 'app/assets/javascripts/work_items/components/item_title.vue' do
              element 'work-item-title'
            end

            base.view 'app/assets/javascripts/work_items/components/notes/work_item_comment_form.vue' do
              element 'confirm-button'
            end

            base.view 'app/assets/javascripts/work_items/components/notes/work_item_note_body.vue' do
              element 'work-item-note-body'
            end

            base.view 'app/assets/javascripts/work_items/components/notes/work_item_notes_activity_header.vue' do
              element 'work-item-filter'
            end
          end

          def comment(text, filter: :all_activities)
            method(:"select_#{filter}_filter").call
            fill_element 'markdown-editor-form-field', "#{text}\n"
            click_element 'confirm-button'
          end

          def has_comment?(comment_text)
            has_element?(
              'work-item-note-body',
              text: comment_text,
              wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME
            )
          end

          def has_system_note?(note_text)
            has_element?('system-note-content', text: note_text, wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)
          end

          def select_all_activities_filter
            select_filter_with_type('ALL_NOTES')

            wait_until do
              has_element?('work-item-filter', text: 'All activity')
            end
          end

          def select_comments_only_filter
            select_filter_with_type('ONLY_COMMENTS')

            wait_until do
              has_element?('work-item-filter', text: 'Comments only')
            end
          end

          def select_history_only_filter
            select_filter_with_type('ONLY_HISTORY')

            wait_until do
              has_element?('work-item-filter', text: 'History only')
            end
          end

          private

          def select_filter_with_type(type)
            retry_on_exception do
              click_element('work-item-title')
              click_element('work-item-filter')
              find_element("listbox-item-#{type}").click

              wait_for_requests
            end
          end
        end
      end
    end
  end
end
