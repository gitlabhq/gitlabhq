# frozen_string_literal: true

module QA
  module Page
    module Component
      module Snippet
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.class_eval do
            include QA::Page::Component::ConfirmModal
          end

          base.view 'app/assets/javascripts/snippets/components/snippet_description_view.vue' do
            element 'snippet-description-content'
          end

          base.view 'app/assets/javascripts/snippets/components/snippet_header.vue' do
            element 'snippet-title-content'
            element 'snippet-container'
            element 'snippet-action-button'
            element 'delete-snippet-button'
            element 'code-button'
          end

          base.view 'app/assets/javascripts/blob/components/blob_header_filepath.vue' do
            element 'file-title-content'
          end

          base.view 'app/assets/javascripts/blob/components/blob_content.vue' do
            element 'blob-viewer-file-content'
          end

          base.view 'app/assets/javascripts/vue_shared/components/code_dropdown/clone_code_dropdown.vue' do
            element 'copy-http-url'
            element 'copy-ssh-url'
          end

          base.view 'app/views/shared/notes/_comment_button.html.haml' do
            element 'comment-button'
          end

          base.view 'app/views/shared/notes/_form.html.haml' do
            element 'note-field'
          end

          base.view 'app/views/projects/notes/_actions.html.haml' do
            element 'edit-comment-button'
          end

          base.view 'app/views/shared/notes/_edit_form.html.haml' do
            element 'edit-note-field'
            element 'save-comment-button'
          end

          base.view 'app/views/shared/notes/_note.html.haml' do
            element 'note-content'
            element 'note-author-content'
          end

          base.view 'app/views/shared/notes/_notes_with_form.html.haml' do
            element 'notes-list'
          end

          base.view 'app/views/projects/notes/_more_actions_dropdown.html.haml' do
            element 'more-actions-dropdown'
            element 'delete-comment-button'
          end

          base.view 'app/assets/javascripts/blob/components/blob_header_default_actions.vue' do
            element 'default-actions-container'
            element 'copy-contents-button'
          end

          base.view 'app/views/layouts/nav/breadcrumbs/_breadcrumbs.html.haml' do
            element 'breadcrumb-links'
          end
        end

        def has_snippet_title?(snippet_title)
          has_element?('snippet-title-content', text: snippet_title, wait: 10)
        end

        def has_snippet_description?(snippet_description)
          has_element? 'snippet-description-content', text: snippet_description
        end

        def has_no_snippet_description?
          has_no_element?('snippet-description-content')
        end

        def has_visibility_description?(visibility_description)
          within_element('snippet-container') do
            has_text?(visibility_description)
          end
        end

        def has_file_name?(file_name, file_number = nil)
          if file_number
            within_element_by_index('file-title-content', file_number - 1) do
              has_text?(file_name)
            end
          else
            within_element('file-title-content') do
              has_text?(file_name)
            end
          end
        end

        def has_no_file_name?(file_name, file_number = nil)
          if file_number
            within_element_by_index('file-title-content', file_number - 1) do
              has_no_text?(file_name)
            end
          else
            within_element('file-title-content') do
              has_no_text?(file_name)
            end
          end
        end

        def has_file_content?(file_content, file_number = nil)
          if file_number
            within_element_by_index('blob-viewer-file-content', file_number - 1) do
              has_text?(file_content)
            end
          else
            within_element('blob-viewer-file-content') do
              has_text?(file_content)
            end
          end
        end

        def has_no_file_content?(file_content, file_number = nil)
          if file_number
            within_element_by_index('blob-viewer-file-content', file_number - 1) do
              has_no_text?(file_content)
            end
          else
            within_element('blob-viewer-file-content') do
              has_no_text?(file_content)
            end
          end
        end

        RSpec::Matchers.define :have_embed_option do
          match do |page|
            page.has_element?('copy-embedded-code')
          end

          match_when_negated do |page|
            page.has_no_element?('copy-embedded-code')
          end
        end

        RSpec::Matchers.define :have_share_option do
          match do |page|
            page.has_element?('copy-share-url')
          end

          match_when_negated do |page|
            page.has_no_element?('copy-share-url')
          end
        end

        def click_edit_button
          click_element('snippet-action-button', Page::Dashboard::Snippet::Edit, action: 'Edit')
        end

        def click_delete_button
          click_element('snippets-more-actions-dropdown-toggle')
          click_button('Delete')
          click_element('delete-snippet-button')
          # wait for the page to reload after deletion
          wait_until(reload: false) do
            has_no_element?('delete-snippet-button') &&
              has_no_element?('snippet-action-button', action: 'Delete')
          end
        end

        def click_code_button
          click_element('code-button')
        end

        def get_repository_uri_http
          click_element('code-button')
          Git::Location.new(find_element('copy-http-url-button')['data-clipboard-text']).uri.to_s
        end

        def get_repository_uri_ssh
          click_element('code-button')
          Git::Location.new(find_element('copy-ssh-url-button')['data-clipboard-text']).uri.to_s
        end

        def get_sharing_link
          click_element('code-button')
          Git::Location.new(find_element('copy-share-url-button')['data-clipboard-text']).uri.to_s
        end

        def add_comment(comment)
          fill_element('note-field', comment)
          click_element('comment-button')

          unless has_element?('note-author-content')
            raise QA::Page::Base::ElementNotFound, "Comment did not appear as expected"
          end
        end

        def has_comment_author?(author_username)
          within_element('note-author-content') do
            has_text?('@' + author_username)
          end
        end

        def has_comment_content?(comment_content)
          within_element('note-content') do
            has_text?(comment_content)
          end
        end

        def within_notes_list(&block)
          within_element 'notes-list', &block
        end

        def has_syntax_highlighting?(language)
          within_element('blob-viewer-file-content') do
            find('.line')['lang'].to_s == language
          end
        end

        def edit_comment(comment)
          click_element('edit-comment-button')
          fill_element('edit-note-field', comment)
          click_element('save-comment-button')

          unless has_element?('note-author-content')
            raise QA::Page::Base::ElementNotFound, "Comment did not appear as expected"
          end
        end

        def delete_comment(comment)
          click_element('more-actions-dropdown')
          click_element('delete-comment-button')
          click_confirmation_ok_button

          unless has_no_element?('note-content', text: comment)
            raise QA::Page::Base::ElementNotFound, "Comment was not removed as expected"
          end
        end

        def click_copy_file_contents(file_number = nil)
          if file_number
            within_element_by_index('default-actions-container', file_number - 1) do
              click_element('copy-contents-button')
            end
          else
            within_element('default-actions-container') do
              click_element('copy-contents-button')
            end
          end
        end

        def copy_file_contents_to_comment(file_number = nil)
          click_copy_file_contents(file_number)
          send_keys_to_element('note-field', [:shift, :insert])

          # on slow connections it takes time for text to appear
          wait_until(reload: false, sleep_interval: 1, message: "Wait for text to be pasted into comment textarea") do
            !find_element('note-field').value.empty?
          end

          click_element('comment-button')

          unless has_element?('note-author-content')
            raise QA::Page::Base::ElementNotFound, "Comment did not appear as expected"
          end
        end

        def snippet_id
          within_element('breadcrumb-links') do
            find('li:last-of-type').text.delete_prefix('$')
          end
        end
      end
    end
  end
end
