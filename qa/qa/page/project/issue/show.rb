# frozen_string_literal: true

module QA
  module Page
    module Project
      module Issue
        class Show < Page::Base
          include Page::Component::Issuable::Common
          include Page::Component::Note

          view 'app/views/shared/notes/_form.html.haml' do
            element :new_note_form, 'new-note' # rubocop:disable QA/ElementWithPattern
            element :new_note_form, 'attr: :note' # rubocop:disable QA/ElementWithPattern
          end

          view 'app/assets/javascripts/notes/components/comment_form.vue' do
            element :comment_button
            element :comment_input
          end

          view 'app/assets/javascripts/notes/components/discussion_filter.vue' do
            element :discussion_filter
            element :filter_options
          end

          view 'app/assets/javascripts/notes/components/noteable_note.vue' do
            element :noteable_note_item
          end

          # Adds a comment to an issue
          # attachment option should be an absolute path
          def comment(text, attachment: nil, filter: :all_activities)
            method("select_#{filter}_filter").call
            fill_element :comment_input, text

            unless attachment.nil?
              QA::Page::Component::Dropzone.new(self, '.new-note')
                .attach_file(attachment)
            end

            click_element :comment_button
          end

          def has_comment?(comment_text)
            wait(reload: false) do
              has_element?(:noteable_note_item, text: comment_text)
            end
          end

          def select_comments_only_filter
            select_filter_with_text('Show comments only')
          end

          def select_history_only_filter
            select_filter_with_text('Show history only')
          end

          def select_all_activities_filter
            select_filter_with_text('Show all activity')
          end

          private

          def select_filter_with_text(text)
            retry_on_exception do
              click_body
              click_element :discussion_filter
              find_element(:filter_options, text: text).click
            end
          end
        end
      end
    end
  end
end
