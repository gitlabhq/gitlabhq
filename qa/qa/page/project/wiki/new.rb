module QA
  module Page
    module Project
      module Wiki
        class New < Page::Base
          view 'app/views/projects/wikis/_form.html.haml' do
            element :wiki_title_textbox, 'text_field :title'
            element :wiki_content_textarea, "render 'projects/zen', f: f, attr: :content"
            element :wiki_message_textbox, 'text_field :message'
            element :save_changes_button, 'submit _("Save changes")'
            element :create_page_button, 'submit s_("Wiki|Create page")'
          end

          view 'app/views/shared/empty_states/_wikis.html.haml' do
            element :create_link, 'Create your first page'
          end

          def go_to_create_first_page
            click_link 'Create your first page'
          end

          def set_title(title)
            fill_in 'wiki_title', with: title
          end

          def set_content(content)
            fill_in 'wiki_content', with: content
          end

          def set_message(message)
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
