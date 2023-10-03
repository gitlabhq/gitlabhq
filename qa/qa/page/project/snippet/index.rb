# frozen_string_literal: true

module QA
  module Page
    module Project
      module Snippet
        class Index < Page::Base
          include Page::Component::Snippet
          include Page::Component::BlobContent

          view 'app/views/shared/snippets/_snippet.html.haml' do
            element 'snippet-link'
          end

          def has_project_snippet?(title)
            has_element?('snippet-link', snippet_title: title)
          end

          def click_snippet_link(title)
            within_element('snippet-link', text: title) do
              click_link(title)
            end
          end
        end
      end
    end
  end
end

QA::Page::Project::Snippet::Index.prepend_mod_with('Page::Project::Snippet::Index', namespace: QA)
