# frozen_string_literal: true

module QA
  module Page
    module Project
      module Snippet
        class New < Page::Base
          include Page::Component::NewSnippet
          include Component::LazyLoader

          view 'app/views/shared/empty_states/_snippets.html.haml' do
            element 'create-first-snippet-link'
            element 'snippets-empty-state'
          end

          def click_create_first_snippet
            finished_loading?

            click_element('create-first-snippet-link')
          end
        end
      end
    end
  end
end
