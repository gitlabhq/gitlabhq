# frozen_string_literal: true

module QA
  module Page
    module File
      module Shared
        module Editor
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.view 'app/views/projects/blob/_editor.html.haml' do
              element 'source-editor-preview-container'
            end
          end

          def add_content(content)
            text_area.set content
          end

          def remove_content
            if page.driver.browser.capabilities.platform_name.include? "mac"
              text_area.send_keys([:command, 'a'], :backspace)
            else
              text_area.send_keys([:control, 'a'], :backspace)
            end
          end

          private

          def text_area
            within_element 'source-editor-preview-container' do
              find('textarea', visible: false)
            end
          end
        end
      end
    end
  end
end
