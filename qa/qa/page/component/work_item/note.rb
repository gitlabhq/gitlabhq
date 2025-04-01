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

            base.view 'app/assets/javascripts/work_items/components/notes/work_item_discussion.vue' do
              element 'note-container'
            end

            base.view 'app/assets/javascripts/work_items/components/notes/work_item_note_body.vue' do
              element 'work-item-note-body'
            end

            base.view 'app/assets/javascripts/work_items/components/notes/work_item_notes_activity_header.vue' do
              element 'work-item-filter'
            end

            base.view 'app/assets/javascripts/work_items/components/notes/work_item_note.vue' do
              element 'note-wrapper'
            end

            base.view 'app/assets/javascripts/work_items/components/notes/work_item_note_actions.vue' do
              element 'note-edit-button'
            end

            base.view 'app/assets/javascripts/notes/components/toggle_replies_widget.vue' do
              element 'expand-replies-button'
              element 'collapse-replies-button'
            end
          end

          def collapse_replies
            click_element 'collapse-replies-button'
          end

          # Attachment option should be an absolute path
          def comment(text, attachment: nil, filter: :all_activities)
            method(:"select_#{filter}_filter").call
            fill_editor_element('markdown-editor-form-field', "#{text}\n")

            unless attachment.nil?
              QA::Page::Component::Dropzone.new(self, '.new-note')
                .attach_file(attachment)
            end

            has_active_element?('confirm-button', wait: 0.5)
            click_element 'confirm-button'
          end

          def edit_comment(text)
            click_element 'note-edit-button'
            within_element 'note-wrapper' do
              fill_and_submit_comment(text)
            end
          end

          def expand_replies
            click_element 'expand-replies-button'
          end

          def has_comment?(comment_text)
            has_element?(
              'work-item-note-body',
              text: comment_text,
              wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME
            )
          end

          def has_comment_author?(author_username)
            within_element('work-item-note-body') do
              has_element?('author-name', text: author_username, wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)
            end
          end

          def has_system_note?(note_text)
            has_element?('system-note-content', text: note_text, wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)
          end

          def noteable_note_item
            find_element('work-item-note-body')
          end

          def reply_to_comment(position, reply_text)
            all_elements('reply-icon', minimum: position)[position - 1].click
            within_element 'note-container' do
              fill_and_submit_comment(reply_text)
            end
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

          def fill_and_submit_comment(text)
            fill_editor_element('markdown-editor-form-field', "#{text}\n")
            has_active_element?('confirm-button', wait: 0.5)
            click_element 'confirm-button'
          end

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
