# frozen_string_literal: true

module QA
  module Page
    module Dashboard
      module Snippet
        class Index < Page::Base
          view 'app/views/shared/snippets/_snippet.html.haml' do
            element 'snippet-link'
            element 'snippet-visibility-content'
            element 'snippet-file-count-content'
          end

          def has_snippet_title?(snippet_title)
            has_element?('snippet-link', snippet_title: snippet_title)
          end

          def has_visibility_level?(snippet_title, visibility)
            within_element('snippet-link', snippet_title: snippet_title) do
              has_element?('snippet-visibility-content', snippet_visibility: visibility)
            end
          end

          def has_number_of_files?(snippet_title, number)
            retry_until(max_attempts: 5, reload: true, sleep_interval: 1) do # snippet statistics computation can take a few moments
              within_element('snippet-link', snippet_title: snippet_title) do
                has_element?('snippet-file-count-content', snippet_files: number, wait: 5)
              end
            end
          end
        end
      end
    end
  end
end
