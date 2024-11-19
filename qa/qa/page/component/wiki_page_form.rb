# frozen_string_literal: true

module QA
  module Page
    module Component
      module WikiPageForm
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/assets/javascripts/pages/shared/wikis/components/wiki_form.vue' do
            element 'wiki-title-textbox'
            element 'wiki-path-textbox'
            element 'wiki-message-textbox'
            element 'wiki-submit-button'
          end

          base.view 'app/assets/javascripts/vue_shared/components/markdown/markdown_editor.vue' do
            element 'markdown-editor-form-field'
          end

          base.view 'app/assets/javascripts/vue_shared/components/markdown/editor_mode_switcher.vue' do
            element 'editing-mode-switcher'
          end

          base.view 'app/assets/javascripts/pages/shared/wikis/components/delete_wiki_modal.vue' do
            element 'delete-button'
          end
        end

        def set_path(path)
          if has_element?('wiki-path-textbox', wait: 0)
            fill_element('wiki-path-textbox', path)
          else
            set_title(path)
          end
        end

        def set_title(title)
          fill_element('wiki-title-textbox', title)
        end

        def set_content(content)
          fill_editor_element('markdown-editor-form-field', content)
        end

        def set_message(message)
          fill_element('wiki-message-textbox', message)
        end

        def click_submit
          # In case any changes were just made, wait for the hidden content field to be updated via a deferred call
          # before clicking submit. See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/97693#note_1098728562
          sleep 0.5

          click_element('wiki-submit-button')

          QA::Support::Retrier.retry_on_exception do
            has_no_element?('wiki-title-textbox')
          end
        end

        def delete_page
          click_element('delete-button', Page::Modal::DeleteWiki)
          Page::Modal::DeleteWiki.perform(&:confirm_deletion)
        end

        def use_new_editor
          return if has_element?('content-editor')

          click_element('editing-mode-switcher')

          wait_until(reload: false) do
            has_element?('content-editor')
          end

          # Remove once tabindex error is fixed: https://gitlab.com/gitlab-org/gitlab/-/issues/493891
          sleep 2
        end
      end
    end
  end
end
