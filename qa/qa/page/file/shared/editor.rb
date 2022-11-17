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
              element :source_editor_preview_container
            end
          end

          def add_content(content)
            text_area.set content
          end

          def remove_content
            if page.driver.browser.capabilities.platform.include? "mac"
              text_area.send_keys([:command, 'a'], :backspace)
            else
              text_area.send_keys([:control, 'a'], :backspace)
            end
          end

          private

          def text_area
            within_element :source_editor_preview_container do
              find('textarea', visible: false)
            end
          end
        end
      end
    end
  end
end
