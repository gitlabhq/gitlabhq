# frozen_string_literal: true

module QA
  module Page
    module Dashboard
      module Snippet
        class Edit < Page::Base
          view 'app/assets/javascripts/snippets/components/edit.vue' do
            element :submit_button, required: true
          end

          view 'app/assets/javascripts/snippets/components/snippet_blob_edit.vue' do
            element :file_name_field
            element :file_holder_container
          end

          view 'app/assets/javascripts/blob/components/blob_edit_header.vue' do
            element :delete_file_button
          end

          view 'app/assets/javascripts/snippets/components/snippet_visibility_edit.vue' do
            element :visibility_content
          end

          def add_to_file_content(content)
            text_area.click
            text_area.send_keys(:home, content) # starts in the beginning of the line
            text_area.has_text?(content) # wait for changes to take effect
          end

          def change_visibility_to(visibility_type)
            click_element(:visibility_content, visibility: visibility_type)
          end

          def click_add_file
            click_element(:add_file_button)
          end

          def fill_file_name(name, file_number = nil)
            if file_number
              within_element_by_index(:file_holder_container, file_number - 1) do
                fill_element(:file_name_field, name)
              end
            else
              fill_element(:file_name_field, name)
            end
          end

          def fill_file_content(content, file_number = nil)
            if file_number
              within_element_by_index(:file_holder_container, file_number - 1) do
                text_area.set(content)
              end
            else
              text_area.set(content)
            end
          end

          def click_delete_file(file_number)
            within_element_by_index(:file_holder_container, file_number - 1) do
              click_element(:delete_file_button)
            end
          end

          def save_changes
            wait_until(reload: false) { !find_element(:submit_button).disabled? }
            click_element(:submit_button, Page::Dashboard::Snippet::Show)
          end

          private

          def text_area
            find('.monaco-editor textarea', visible: false)
          end
        end
      end
    end
  end
end
