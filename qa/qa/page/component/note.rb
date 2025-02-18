# frozen_string_literal: true

module QA
  module Page
    module Component
      module Note
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/assets/javascripts/diffs/components/diff_file_header.vue' do
            element 'toggle-comments-button'
          end

          base.view 'app/assets/javascripts/notes/components/comment_form.vue' do
            element 'comment-field'
            element 'add-to-review-button'
            element 'start-review-button'
          end

          base.view 'app/assets/javascripts/notes/components/comment_type_dropdown.vue' do
            element 'comment-button'
            element 'discussion-menu-item'
          end

          base.view 'app/assets/javascripts/notes/components/discussion_actions.vue' do
            element 'resolve-discussion-button'
          end

          base.view 'app/assets/javascripts/notes/components/discussion_filter.vue' do
            element 'discussion-preferences-dropdown'
            element 'filter-menu-item'
          end

          base.view 'app/assets/javascripts/notes/components/discussion_filter_note.vue' do
            element 'discussion-filter-container'
          end

          base.view 'app/assets/javascripts/notes/components/discussion_reply_placeholder.vue' do
            element 'discussion-reply-tab'
          end

          base.view 'app/assets/javascripts/notes/components/noteable_discussion.vue' do
            element 'discussion-content'
          end

          base.view 'app/assets/javascripts/notes/components/noteable_note.vue' do
            element 'noteable-note-container'
          end

          base.view 'app/assets/javascripts/notes/components/note_actions.vue' do
            element 'note-edit-button'
          end

          base.view 'app/assets/javascripts/notes/components/note_form.vue' do
            element 'reply-field'
            element 'reply-comment-button'
          end

          base.view 'app/assets/javascripts/notes/components/note_header.vue' do
            element 'system-note-content'
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
          method("select_#{filter}_filter").call
          fill_editor_element 'comment-field', "#{text}\n"

          unless attachment.nil?
            QA::Page::Component::Dropzone.new(self, '.new-note')
              .attach_file(attachment)
          end

          has_active_element?('comment-button', wait: 0.5)
          click_element 'comment-button'
        end

        def edit_comment(text)
          click_element 'note-edit-button'
          fill_editor_element 'reply-field', text
          has_active_element?('reply-comment-button', wait: 0.5)
          click_element 'reply-comment-button'
        end

        def expand_replies
          click_element 'expand-replies-button'
        end

        def has_comment?(comment_text)
          has_element?(
            'noteable-note-container',
            text: comment_text,
            wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME
          )
        end

        def has_comment_author?(author_username)
          within_element('noteable-note-container') do
            has_element?('author-name', text: author_username, wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)
          end
        end

        def has_system_note?(note_text)
          has_element?('system-note-content', text: note_text, wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)
        end

        def noteable_note_item
          find_element('noteable-note-container')
        end

        def reply_to_discussion(position, reply_text)
          type_reply_to_discussion(position, reply_text)
          has_active_element?('reply-comment-button', wait: 0.5)
          click_element 'reply-comment-button'
        end

        def resolve_discussion_at_index(index)
          within_element_by_index('discussion-content', index) do
            click_element 'resolve-discussion-button'
          end
        end

        def select_all_activities_filter
          select_filter_with_text('Show all activity')

          wait_until do
            has_no_element?('discussion-filter-container') && has_element?('comment-field')
          end
        end

        def select_comments_only_filter
          select_filter_with_text('Show comments only')

          wait_until do
            has_no_element?('discussion-filter-container') && has_no_element?('system-note-content')
          end
        end

        def select_history_only_filter
          select_filter_with_text('Show history only')

          wait_until do
            has_element?('discussion-filter-container') && has_no_element?('noteable-note-container')
          end
        end

        def start_discussion(text)
          fill_editor_element 'comment-field', text
          within_element('comment-button') { click_button(class: 'gl-new-dropdown-toggle') }
          click_element 'discussion-menu-item'
          click_element 'comment-button'

          has_comment?(text)
        end

        def start_review_with_comment(text)
          fill_editor_element 'comment-field', text
          click_element 'start-review-button'
          has_comment?(text)
        end

        def add_comment_to_review(text)
          fill_editor_element 'comment-field', text
          click_element 'add-to-review-button'
          has_comment?(text)
        end

        def toggle_comments(position)
          all_elements('toggle-comments-button', minimum: position)[position - 1].click
        end

        def type_reply_to_discussion(position, reply_text)
          all_elements('discussion-reply-tab', minimum: position)[position - 1].click
          fill_editor_element 'reply-field', reply_text
        end

        private

        def select_filter_with_text(text)
          retry_on_exception do
            click_element('issue-title')
            click_element 'discussion-preferences-dropdown'
            find_element('filter-menu-item', text: text).click

            wait_for_requests
          end
        end
      end
    end
  end
end
