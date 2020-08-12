# frozen_string_literal: true

module QA
  module Page
    module Dashboard
      module Snippet
        class Show < Page::Base
          include Page::Component::Snippet

          view 'app/assets/javascripts/snippets/components/snippet_title.vue' do
            element :snippet_title_content, required: true
          end
        end
      end
    end
  end
end
