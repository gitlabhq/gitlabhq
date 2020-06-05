# frozen_string_literal: true

module QA
  module Page
    module Dashboard
      module Snippet
        class Show < Page::Base
          view 'app/assets/javascripts/snippets/components/snippet_description_view.vue' do
            element :snippet_description_content
          end

          view 'app/assets/javascripts/snippets/components/snippet_title.vue' do
            element :snippet_title_content, required: true
          end

          view 'app/assets/javascripts/snippets/components/snippet_header.vue' do
            element :snippet_container
          end

          view 'app/assets/javascripts/blob/components/blob_header_filepath.vue' do
            element :file_title_content
          end

          view 'app/assets/javascripts/vue_shared/components/blob_viewers/simple_viewer.vue' do
            element :file_content
          end

          view 'app/assets/javascripts/blob/components/blob_content.vue' do
            element :file_content
          end

          view 'app/assets/javascripts/snippets/components/snippet_header.vue' do
            element :snippet_action_button
            element :delete_snippet_button
          end

          view 'app/assets/javascripts/snippets/components/snippet_blob_view.vue' do
            element :clone_button
          end

          view 'app/assets/javascripts/vue_shared/components/clone_dropdown.vue' do
            element :copy_http_url_button
            element :copy_ssh_url_button
          end

          def has_snippet_title?(snippet_title)
            has_element? :snippet_title_content, text: snippet_title
          end

          def has_snippet_description?(snippet_description)
            has_element? :snippet_description_content, text: snippet_description
          end

          def has_no_snippet_description?
            has_no_element?(:snippet_description_field)
          end

          def has_visibility_type?(visibility_type)
            within_element(:snippet_container) do
              has_text?(visibility_type)
            end
          end

          def has_file_name?(file_name)
            within_element(:file_title_content) do
              has_text?(file_name)
            end
          end

          def has_file_content?(file_content)
            finished_loading?
            within_element(:file_content) do
              has_text?(file_content)
            end
          end

          def click_edit_button
            finished_loading?
            click_element(:snippet_action_button, action: 'Edit')
          end

          def click_delete_button
            finished_loading?
            click_element(:snippet_action_button, action: 'Delete')
            click_element(:delete_snippet_button)
            finished_loading? # wait for the page to reload after deletion
          end

          def get_repository_uri_http
            finished_loading?
            click_element(:clone_button)
            Git::Location.new(find_element(:copy_http_url_button)['data-clipboard-text']).uri.to_s
          end

          def get_repository_uri_ssh
            finished_loading?
            click_element(:clone_button)
            Git::Location.new(find_element(:copy_ssh_url_button)['data-clipboard-text']).uri.to_s
          end
        end
      end
    end
  end
end
