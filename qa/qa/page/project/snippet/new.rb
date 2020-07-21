# frozen_string_literal: true

module QA
  module Page
    module Project
      module Snippet
        class New < Page::Base
          include Page::Component::NewSnippet
          include Component::LazyLoader
          view 'app/views/shared/empty_states/_snippets.html.haml' do
            element :create_first_snippet_link
            element :svg_content
          end

          def click_create_first_snippet
            finished_loading?

            # The svg takes a fraction of a second to load after which the
            # "New snippet" button shifts up a bit. This can cause
            # webdriver to miss the hit so we wait for the svg to load before
            # clicking the button.
            within_element(:svg_content) do
              has_element?(:js_lazy_loaded)
            end
            click_element(:create_first_snippet_link)
          end
        end
      end
    end
  end
end
