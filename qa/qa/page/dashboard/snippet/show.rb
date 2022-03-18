# frozen_string_literal: true

module QA
  module Page
    module Dashboard
      module Snippet
        class Show < Page::Base
          include Page::Component::Snippet
          include Page::Component::BlobContent

          view 'app/assets/javascripts/snippets/components/snippet_title.vue' do
            element :snippet_title_content
          end
        end
      end
    end
  end
end
