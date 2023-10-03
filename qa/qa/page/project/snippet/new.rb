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
            element 'svg-content'
          end

          def click_create_first_snippet
            finished_loading?

            # The svg takes a fraction of a second to load after which the
            # "New snippet" button shifts up a bit. This can cause
            # webdriver to miss the hit so we wait for the svg to load before
            # clicking the button.
            within_element('svg-content') do
              has_element?('js-lazy-loaded-content')
            end
            click_element('create-first-snippet-link')
          end
        end
      end
    end
  end
end
