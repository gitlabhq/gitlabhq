# frozen_string_literal: true

module QA
  module Page
    module Project
      module Snippet
        class Show < Page::Base
          include Page::Component::Snippet
          include Page::Component::BlobContent

          view 'app/views/projects/notes/_actions.html.haml' do
            element 'edit-comment-button'
          end
        end
      end
    end
  end
end
