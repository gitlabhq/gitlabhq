# frozen_string_literal: true

module QA
  module Page
    module Dashboard
      module Snippet
        class New < Page::Base
          view 'app/assets/javascripts/snippets/components/edit.vue' do
            element :snippet_title_field, required: true
            element :submit_button
          end

          view 'app/assets/javascripts/snippets/components/snippet_description_edit.vue' do
            element :snippet_description_field
            element :description_placeholder, required: true
          end

          view 'app/assets/javascripts/snippets/components/snippet_blob_edit.vue' do
            element :file_name_field
          end

          view 'app/views/shared/form_elements/_description.html.haml' do
            element :issuable_form_description
          end

          view 'app/views/shared/snippets/_form.html.haml' do
            element :snippet_description_field
            element :description_placeholder
            element :snippet_title_field
            element :file_name_field
            element :submit_button
          end

          view 'app/views/projects/_zen.html.haml' do
            # This 'element' is here only to ensure the changes in the view source aren't mistakenly changed
            element :_, "qa_selector = local_assigns.fetch(:qa_selector, '')" # rubocop:disable QA/ElementWithPattern
          end

          def fill_title(title)
            fill_element :snippet_title_field, title
          end

          def fill_description(description)
            click_element :description_placeholder
            fill_element :snippet_description_field, description
          end

          def set_visibility(visibility)
            choose visibility
          end

          def fill_file_name(name)
            finished_loading?
            fill_element :file_name_field, name
          end

          def fill_file_content(content)
            finished_loading?
            text_area.set content
          end

          def click_create_snippet_button
            wait_until(reload: false) { !find_element(:submit_button).disabled? }
            click_element :submit_button
          end

          private

          def text_area
            find('#editor textarea', visible: false)
          end
        end
      end
    end
  end
end
