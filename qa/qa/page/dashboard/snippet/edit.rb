# frozen_string_literal: true

module QA
  module Page
    module Dashboard
      module Snippet
        class Edit < Page::Base
          view 'app/assets/javascripts/snippets/components/edit.vue' do
            element :submit_button, required: true
          end

          def add_to_file_content(content)
            text_area.set content
            text_area.has_text?(content) # wait for changes to take effect
          end

          def change_visibility_to(visibility_type)
            choose(visibility_type)
          end

          def save_changes
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
