module QA
  module Page
    module Project
      module Wiki
        class Form < Page::Base
          view 'app/views/projects/wikis/_form.html.haml' do
            element :wiki_title_textbox, 'f.text_field :title'
            element :wiki_content_textarea, "render 'projects/zen', f: f, attr: :content"
            element :wiki_message_textbox, 'f.text_field :message'
            element :save_changes_button, 'f.submit _("Save changes")'
            element :create_page_button, 'f.submit s_("Wiki|Create page")'
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

          def create_new_page
            click_on 'Create page'
          end
        end
      end
    end
  end
end
