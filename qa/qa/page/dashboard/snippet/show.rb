# frozen_string_literal: true

module QA
  module Page
    module Dashboard
      module Snippet
        class Show < Page::Base
          view 'app/views/shared/snippets/_header.html.haml' do
            element :snippet_title, required: true
            element :snippet_description, required: true
            element :embed_type
            element :snippet_box
          end

          view 'app/views/projects/blob/_header_content.html.haml' do
            element :file_title_name
          end

          view 'app/views/shared/_file_highlight.html.haml' do
            element :file_content
          end

          def has_snippet_title?(snippet_title)
            has_element? :snippet_title, text: snippet_title
          end

          def has_snippet_description?(snippet_description)
            has_element? :snippet_description, text: snippet_description
          end

          def has_embed_type?(embed_type)
            within_element(:embed_type) do
              has_text?(embed_type)
            end
          end

          def has_visibility_type?(visibility_type)
            within_element(:snippet_box) do
              has_text?(visibility_type)
            end
          end

          def has_file_name?(file_name)
            within_element(:file_title_name) do
              has_text?(file_name)
            end
          end

          def has_file_content?(file_content)
            finished_loading?
            within_element(:file_content) do
              has_text?(file_content)
            end
          end
        end
      end
    end
  end
end
