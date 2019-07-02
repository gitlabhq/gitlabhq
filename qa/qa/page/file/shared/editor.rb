# frozen_string_literal: true

module QA
  module Page
    module File
      module Shared
        module Editor
          def self.included(base)
            base.view 'app/views/projects/blob/_editor.html.haml' do
              element :editor
            end
          end

          def add_content(content)
            text_area.set content
          end

          def remove_content
            text_area.send_keys([:command, 'a'], :backspace)
          end

          private

          def text_area
            within_element :editor do
              find('textarea', visible: false)
            end
          end
        end
      end
    end
  end
end
