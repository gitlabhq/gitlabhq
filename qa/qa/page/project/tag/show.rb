# frozen_string_literal: true

module QA
  module Page
    module Project
      module Tag
        class Show < Page::Base
          view 'app/views/projects/tags/show.html.haml' do
            element 'tag-name-content'
            element 'tag-message-content'
          end

          def has_tag_name?(text)
            has_element?('tag-name-content', text: text)
          end

          def has_tag_message?(text)
            has_element?('tag-message-content', text: text)
          end
        end
      end
    end
  end
end
