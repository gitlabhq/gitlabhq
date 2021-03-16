# frozen_string_literal: true

module QA
  module Page
    module Component
      module NewSnippet
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/assets/javascripts/snippets/components/edit.vue' do
            element :snippet_title_field, required: true
            element :submit_button
          end

          base.view 'app/assets/javascripts/snippets/components/snippet_description_edit.vue' do
            element :snippet_description_field
            element :description_placeholder, required: true
          end

          base.view 'app/assets/javascripts/snippets/components/snippet_blob_edit.vue' do
            element :file_name_field
            element :file_holder_container
          end

          base.view 'app/assets/javascripts/snippets/components/snippet_blob_actions_edit.vue' do
            element :add_file_button
          end

          base.view 'app/views/shared/_zen.html.haml' do
            # This 'element' is here only to ensure the changes in the view source aren't mistakenly changed
            element :_, "qa_selector = local_assigns.fetch(:qa_selector, '')" # rubocop:disable QA/ElementWithPattern
          end

          base.view 'app/assets/javascripts/snippets/components/snippet_visibility_edit.vue' do
            element :visibility_content
          end
        end

        def fill_title(title)
          fill_element :snippet_title_field, title
        end

        def fill_description(description)
          click_element :description_placeholder
          fill_element :snippet_description_field, description
        end

        def set_visibility(visibility)
          click_element(:visibility_content, visibility: visibility)
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
            text_area.set content
          end
        end

        def click_add_file
          click_element(:add_file_button)
        end

        def click_create_snippet_button
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
