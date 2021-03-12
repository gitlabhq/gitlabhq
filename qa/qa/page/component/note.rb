# frozen_string_literal: true

module QA
  module Page
    module Component
      module Note
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/assets/javascripts/diffs/components/diff_file_header.vue' do
            element :toggle_comments_button
          end

          base.view 'app/assets/javascripts/notes/components/comment_form.vue' do
            element :comment_button
            element :comment_field
            element :discussion_menu_item
          end

          base.view 'app/assets/javascripts/notes/components/discussion_actions.vue' do
            element :discussion_reply_tab
            element :resolve_discussion_button
          end

          base.view 'app/assets/javascripts/notes/components/discussion_filter.vue' do
            element :discussion_filter_dropdown, required: true
            element :filter_menu_item
          end

          base.view 'app/assets/javascripts/notes/components/discussion_filter_note.vue' do
            element :discussion_filter_container
          end

          base.view 'app/assets/javascripts/notes/components/noteable_discussion.vue' do
            element :discussion_content
          end

          base.view 'app/assets/javascripts/notes/components/noteable_note.vue' do
            element :noteable_note_container
          end

          base.view 'app/assets/javascripts/notes/components/note_actions.vue' do
            element :note_edit_button
          end

          base.view 'app/assets/javascripts/notes/components/note_form.vue' do
            element :reply_field
            element :reply_comment_button
          end

          base.view 'app/assets/javascripts/notes/components/note_header.vue' do
            element :system_note_content
          end

          base.view 'app/assets/javascripts/notes/components/toggle_replies_widget.vue' do
            element :expand_replies_button
            element :collapse_replies_button
          end

          base.view 'app/assets/javascripts/vue_shared/components/notes/skeleton_note.vue' do
            element :skeleton_note_placeholder
          end

          base.view 'app/views/shared/notes/_form.html.haml' do
            element :new_note_form, 'new-note' # rubocop:disable QA/ElementWithPattern
            element :new_note_form, 'attr: :note' # rubocop:disable QA/ElementWithPattern
          end
        end

        def collapse_replies
          click_element :collapse_replies_button
        end

        # Attachment option should be an absolute path
        def comment(text, attachment: nil, filter: :all_activities)
          method("select_#{filter}_filter").call
          fill_element :comment_field, "#{text}\n"

          unless attachment.nil?
            QA::Page::Component::Dropzone.new(self, '.new-note')
              .attach_file(attachment)
          end

          click_element :comment_button
        end

        def edit_comment(text)
          click_element :note_edit_button
          fill_element :reply_field, text
          click_element :reply_comment_button
        end

        def expand_replies
          click_element :expand_replies_button
        end

        def has_comment?(comment_text)
          has_element?(:noteable_note_container, text: comment_text, wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)
        end

        def has_system_note?(note_text)
          has_element?(:system_note_content, text: note_text, wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)
        end

        def noteable_note_item
          find_element(:noteable_note_container)
        end

        def reply_to_discussion(position, reply_text)
          type_reply_to_discussion(position, reply_text)
          click_element :reply_comment_button
        end

        def resolve_discussion_at_index(index)
          within_element_by_index(:discussion_content, index) do
            click_element :resolve_discussion_button
          end
        end

        def select_all_activities_filter
          select_filter_with_text('Show all activity')

          wait_until do
            has_no_element?(:discussion_filter_container) && has_element?(:comment_field)
          end
        end

        def select_comments_only_filter
          select_filter_with_text('Show comments only')

          wait_until do
            has_no_element?(:discussion_filter_container) && has_no_element?(:system_note_content)
          end
        end

        def select_history_only_filter
          select_filter_with_text('Show history only')

          wait_until do
            has_element?(:discussion_filter_container) && has_no_element?(:noteable_note_container)
          end
        end

        def start_discussion(text)
          fill_element :comment_field, text
          within_element(:comment_button) { click_button(class: 'dropdown-toggle-split') }
          click_element :discussion_menu_item
          click_element :comment_button

          has_comment?(text)
        end

        def toggle_comments(position)
          all_elements(:toggle_comments_button, minimum: position)[position - 1].click
        end

        def type_reply_to_discussion(position, reply_text)
          all_elements(:discussion_reply_tab, minimum: position)[position - 1].click
          fill_element :reply_field, reply_text
        end

        private

        def select_filter_with_text(text)
          retry_on_exception do
            click_element(:title)
            click_element :discussion_filter_dropdown
            find_element(:filter_menu_item, text: text).click

            wait_for_requests
          end
        end
      end
    end
  end
end
