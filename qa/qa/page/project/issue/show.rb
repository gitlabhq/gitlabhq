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

          # Adds a comment to an issue
          # attachment option should be an absolute path
          def comment(text, attachment: nil)
            fill_element :comment_input, text

            unless attachment.nil?
              QA::Page::Component::Dropzone.new(self, '.new-note')
                .attach_file(attachment)
            end

            click_element :comment_button
          end

          def select_comments_only_filter
            click_element :discussion_filter
            find_element(:filter_options, "Show comments only").click
          end

          def select_history_only_filter
            click_element :discussion_filter
            find_element(:filter_options, "Show history only").click
          end

          def select_all_activities_filter
            click_element :discussion_filter
            find_element(:filter_options, "Show all activity").click
          end
        end
      end
    end
  end
end
