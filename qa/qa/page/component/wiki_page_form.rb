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
            element :wiki_message_textbox
            element :wiki_submit_button
          end

          base.view 'app/assets/javascripts/vue_shared/components/markdown/markdown_editor.vue' do
            element :markdown_editor_form_field
          end

          base.view 'app/assets/javascripts/vue_shared/components/markdown/editor_mode_switcher.vue' do
            element :editing_mode_switcher
          end

          base.view 'app/assets/javascripts/pages/shared/wikis/components/delete_wiki_modal.vue' do
            element :delete_button
          end
        end

        def set_title(title)
          fill_element(:wiki_title_textbox, title)
        end

        def set_content(content)
          fill_element(:markdown_editor_form_field, content)
        end

        def set_message(message)
          fill_element(:wiki_message_textbox, message)
        end

        def click_submit
          # In case any changes were just made, wait for the hidden content field to be updated via a deferred call
          # before clicking submit. See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/97693#note_1098728562
          sleep 0.5

          click_element(:wiki_submit_button)

          QA::Support::Retrier.retry_on_exception do
            has_no_element?(:wiki_title_textbox)
          end
        end

        def delete_page
          click_element(:delete_button, Page::Modal::DeleteWiki)
          Page::Modal::DeleteWiki.perform(&:confirm_deletion)
        end

        def use_new_editor
          click_element(:editing_mode_switcher)

          wait_until(reload: false) do
            has_element?(:content_editor_container)
          end
        end
      end
    end
  end
end
