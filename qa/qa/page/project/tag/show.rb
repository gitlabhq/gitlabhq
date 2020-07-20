# frozen_string_literal: true

module QA
  module Page
    module Project
      module Tag
        class Show < Page::Base
          view 'app/views/projects/tags/show.html.haml' do
            element :tag_name_content
            element :tag_message_content
            element :tag_release_notes_content
          end

          def has_tag_name?(text)
            has_element?(:tag_name_content, text: text)
          end

          def has_tag_message?(text)
            has_element?(:tag_message_content, text: text)
          end

          def has_tag_release_notes?(text)
            has_element?(:tag_release_notes_content, text: text)
          end
        end
      end
    end
  end
end
