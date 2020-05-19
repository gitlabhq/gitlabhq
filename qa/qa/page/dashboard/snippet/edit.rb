# frozen_string_literal: true

module QA
  module Page
    module Dashboard
      module Snippet
        class Edit < Page::Base
          view 'app/views/shared/snippets/_form.html.haml' do
            element :submit_button
          end

          view 'app/assets/javascripts/snippets/components/edit.vue' do
            element :submit_button
          end

          def add_to_file_content(content)
            finished_loading?
            text_area.set content
            text_area.has_text?(content) # wait for changes to take effect
          end

          def save_changes
            click_element(:submit_button)
            wait_until { assert_no_element(:submit_button) }
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
