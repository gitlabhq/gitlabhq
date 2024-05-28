# frozen_string_literal: true

module QA
  module Page
    module Component
      module NewSnippet
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/assets/javascripts/snippets/components/edit.vue' do
            element 'snippet-title-input-field', required: true
            element 'submit-button'
          end

          base.view 'app/assets/javascripts/snippets/components/snippet_description_edit.vue' do
            element 'snippet-description-field', required: true
          end

          base.view 'app/assets/javascripts/snippets/components/snippet_blob_edit.vue' do
            element 'file-name-field'
            element 'file-holder-container'
          end

          base.view 'app/assets/javascripts/snippets/components/snippet_blob_actions_edit.vue' do
            element 'add-button'
          end

          base.view 'app/views/shared/_zen.html.haml' do
            # This 'element' is here only to ensure the changes in the view source aren't mistakenly changed
            element :_, "testid = local_assigns.fetch(:testid, '')" # rubocop:disable QA/ElementWithPattern
          end

          base.view 'app/assets/javascripts/snippets/components/snippet_visibility_edit.vue' do
            element 'visibility-content'
          end
        end

        def fill_title(title)
          fill_element 'snippet-title-input-field', title
        end

        def fill_description(description)
          fill_element 'snippet-description-field', description
        end

        def set_visibility(visibility)
          click_element('visibility-content', visibility: visibility)
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
            text_area.set content
          end
        end

        def click_add_file
          click_element('add-button')
        end

        def click_create_snippet_button
          click_element_coordinates('submit-button')
          wait_until(reload: false) do
            has_no_element?('snippet-title-input-field')
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
