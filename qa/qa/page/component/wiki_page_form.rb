# frozen_string_literal: true

module QA
  module Page
    module Component
      module WikiPageForm
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/assets/javascripts/pages/shared/wikis/components/wiki_form.vue' do
            element :wiki_title_textbox
            element :wiki_content_textarea
            element :wiki_message_textbox
            element :wiki_submit_button
          end

          base.view 'app/assets/javascripts/pages/shared/wikis/components/delete_wiki_modal.vue' do
            element :delete_button
          end
        end

        def set_title(title)
          fill_element(:wiki_title_textbox, title)
        end

        def set_content(content)
          fill_element(:wiki_content_textarea, content)
        end

        def set_message(message)
          fill_element(:wiki_message_textbox, message)
        end

        def click_submit
          click_element(:wiki_submit_button)
        end

        def delete_page
          click_element(:delete_button, Page::Modal::DeleteWiki)
          Page::Modal::DeleteWiki.perform(&:confirm_deletion)
        end
      end
    end
  end
end
