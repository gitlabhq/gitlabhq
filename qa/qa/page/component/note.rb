# frozen_string_literal: true

module QA
  module Page
    module Component
      module Note
        def self.included(base)
          base.view 'app/assets/javascripts/notes/components/comment_form.vue' do
            element :note_dropdown
            element :discussion_option
          end

          base.view 'app/assets/javascripts/notes/components/noteable_discussion.vue' do
            element :discussion_content
          end

          base.view 'app/assets/javascripts/notes/components/note_actions.vue' do
            element :note_edit_button
          end

          base.view 'app/assets/javascripts/notes/components/note_form.vue' do
            element :reply_input
            element :reply_comment_button
          end

          base.view 'app/assets/javascripts/notes/components/discussion_actions.vue' do
            element :discussion_reply_tab
            element :resolve_discussion_button
          end

          base.view 'app/assets/javascripts/notes/components/toggle_replies_widget.vue' do
            element :expand_replies
            element :collapse_replies
          end

          base.view 'app/assets/javascripts/diffs/components/diff_file_header.vue' do
            element :toggle_comments_button
          end
        end

        def start_discussion(text)
          fill_element :comment_input, text
          click_element :note_dropdown
          click_element :discussion_option
          click_element :comment_button
        end

        def toggle_comments(position)
          all_elements(:toggle_comments_button, minimum: position)[position - 1].click
        end

        def type_reply_to_discussion(position, reply_text)
          all_elements(:discussion_reply_tab, minimum: position)[position - 1].click
          fill_element :reply_input, reply_text
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

        def collapse_replies
          click_element :collapse_replies
        end

        def expand_replies
          click_element :expand_replies
        end

        def edit_comment(text)
          click_element :note_edit_button
          fill_element :reply_input, text
          click_element :reply_comment_button
        end
      end
    end
  end
end
