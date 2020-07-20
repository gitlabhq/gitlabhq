# frozen_string_literal: true

module QA
  module Page
    module Project
      module Wiki
        class Edit < Base
          include Wiki::Sidebar

          view 'app/views/shared/wikis/_form.html.haml' do
            element :wiki_title_textbox
            element :wiki_content_textarea
            element :wiki_message_textbox
            element :save_changes_button
            element :create_page_button
          end

          view 'app/assets/javascripts/pages/shared/wikis/components/delete_wiki_modal.vue' do
            element :delete_button
          end

          def set_title(title)
            fill_element :wiki_title_textbox, title
          end

          def set_content(content)
            fill_element :wiki_content_textarea, content
          end

          def set_message(message)
            fill_element :wiki_message_textbox, message
          end

          def click_save_changes
            click_element :save_changes_button
          end

          def click_create_page
            click_element :create_page_button
          end

          def delete_page
            click_element :delete_button, Page::Modal::DeleteWiki
            Page::Modal::DeleteWiki.perform(&:confirm_deletion)
          end
        end
      end
    end
  end
end
