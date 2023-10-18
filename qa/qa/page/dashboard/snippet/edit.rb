# frozen_string_literal: true

module QA
  module Page
    module Dashboard
      module Snippet
        class Edit < Page::Base
          view 'app/assets/javascripts/snippets/components/edit.vue' do
            element 'submit-button', required: true
          end

          view 'app/assets/javascripts/snippets/components/snippet_blob_edit.vue' do
            element 'file-name-field'
            element 'file-holder-container'
          end

          view 'app/assets/javascripts/blob/components/blob_edit_header.vue' do
            element 'delete-file-button'
          end

          view 'app/assets/javascripts/snippets/components/snippet_visibility_edit.vue' do
            element 'visibility-content'
          end

          def add_to_file_content(content)
            text_area.click
            text_area.send_keys(:home, content) # starts in the beginning of the line
            wait_until(message: "add_to_file_content", max_duration: Capybara.default_max_wait_time, reload: false) do
              text_area.value.include?(content) # wait for changes to take effect
            end
          end

          def change_visibility_to(visibility_type)
            click_element('visibility-content', visibility: visibility_type)
          end

          def click_add_file
            click_element('add-button')
          end

          def fill_file_name(name, file_number = nil)
            if file_number
              within_element_by_index('file-holder-container', file_number - 1) do
                fill_element('file-name-field', name)
              end
            else
              fill_element('file-name-field', name)
            end
          end

          def fill_file_content(content, file_number = nil)
            if file_number
              within_element_by_index('file-holder-container', file_number - 1) do
                text_area.set(content)
              end
            else
              text_area.set(content)
            end
          end

          def click_delete_file(file_number)
            within_element_by_index('file-holder-container', file_number - 1) do
              click_element('delete-file-button')
            end
          end

          def save_changes
            click_element_coordinates('submit-button')
            wait_until(reload: false) do
              has_no_element?('file-name-field')
            end
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
