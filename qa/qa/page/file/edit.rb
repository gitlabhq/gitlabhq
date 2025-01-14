# frozen_string_literal: true

module QA
  module Page
    module File
      class Edit < Page::Base
        include Shared::CommitMessage
        include Shared::Editor

        def has_markdown_preview?(component, content)
          within_element('source-editor-preview-container') do
            has_css?(component, exact_text: content)
          end
        end

        def preview
          click_link('Preview')
        end
      end
    end
  end
end
