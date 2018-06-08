module QA
  module Page
    module Project
      module Wiki
        class Edit < Page::Base
          view 'app/views/projects/wikis/edit.html.haml' do
            # element :submit_issue_button, 'form.submit "Save changes"'
            # element :wiki_title_textbox, 'form.text_field :title'
            # element :wiki_content_textarea, "render 'projects/zen', f: form, attr: :content"
            # element :wiki_message_textbox, 'form.text_field :message'
          end

          def add_title(title)
            fill_in 'wiki_title', with: title
          end

          def add_content(content)
            fill_in 'wiki_content', with: content
          end

          def add_message(message)
            fill_in 'wiki_message', with: message
          end

          def save_changes
            click_on 'Save changes'
          end
        end
      end
    end
  end
end
