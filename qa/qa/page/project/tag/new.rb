# frozen_string_literal: true

module QA
  module Page
    module Project
      module Tag
        class New < Page::Base
          view 'app/views/projects/tags/new.html.haml' do
            element :tag_name_field
            element :tag_message_field
            element :release_notes_field
            element :create_tag_button
          end

          view 'app/views/shared/_zen.html.haml' do
            # This partial adds the `release_notes_field` selector passed from 'app/views/projects/tags/new.html.haml'
            # The checks below ensure that required lines are not removed without updating this page object
            element :_, "qa_selector = local_assigns.fetch(:qa_selector, '')" # rubocop:disable QA/ElementWithPattern
            element :_, "text_area_tag attr, current_text, data: { qa_selector: qa_selector }" # rubocop:disable QA/ElementWithPattern
          end

          def fill_tag_name(text)
            fill_element(:tag_name_field, text)
          end

          def fill_tag_message(text)
            fill_element(:tag_message_field, text)
          end

          def fill_release_notes(text)
            fill_element(:release_notes_field, text)
          end

          def click_create_tag_button
            click_element :create_tag_button
          end
        end
      end
    end
  end
end
