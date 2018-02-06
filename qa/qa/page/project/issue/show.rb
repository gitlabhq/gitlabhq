module QA
  module Page
    module Project
      module Issue
        class Show < Page::Base
          view 'app/views/projects/issues/show.html.haml' do
            element :issue_details, '.issue-details'
            element :title, '.title'
          end

          view 'app/views/shared/notes/_form.html.haml' do
            element :new_note_form, 'new-note'
            element :new_note_form, 'attr: :note'
          end

          view 'app/views/shared/notes/_comment_button.html.haml' do
            element :comment_button, '%strong Comment'
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
