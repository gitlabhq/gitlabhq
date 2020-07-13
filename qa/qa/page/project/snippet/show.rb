# frozen_string_literal: true

module QA
  module Page
    module Project
      module Snippet
        class Show < Page::Base
          include Page::Component::Snippet

          view 'app/views/projects/notes/_actions.html.haml' do
            element :edit_comment_button
          end
        end
      end
    end
  end
end
