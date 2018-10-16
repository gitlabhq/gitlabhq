# frozen_string_literal: true

module QA
  module Page
    module Project
      module Issue
        class Show < Page::Base
          include Page::Component::Issuable::Common

          view 'app/views/projects/issues/show.html.haml' do
            element :issue_details, '.issue-details' # rubocop:disable QA/ElementWithPattern
            element :title, '.title' # rubocop:disable QA/ElementWithPattern
          end

          view 'app/views/shared/notes/_form.html.haml' do
            element :new_note_form, 'new-note' # rubocop:disable QA/ElementWithPattern
            element :new_note_form, 'attr: :note' # rubocop:disable QA/ElementWithPattern
          end

          view 'app/views/shared/notes/_comment_button.html.haml' do
            element :comment_button, '%strong Comment' # rubocop:disable QA/ElementWithPattern
          end

          def issue_title
            find('.issue-details .title').text
          end

          # Adds a comment to an issue
          # attachment option should be an absolute path
          def comment(text, attachment: nil)
            fill_in(with: text, name: 'note[note]')

            unless attachment.nil?
              QA::Page::Component::Dropzone.new(self, '.new-note')
                .attach_file(attachment)
            end

            click_on 'Comment'
          end
        end
      end
    end
  end
end
