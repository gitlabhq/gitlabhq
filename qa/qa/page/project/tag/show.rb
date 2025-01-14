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

          view 'app/views/projects/tags/_release_link.html.haml' do
            element 'release-link'
          end

          def has_tag_name?(text)
            has_element?('tag-name-content', text: text)
          end

          def has_tag_message?(text)
            has_element?('tag-message-content', text: text)
          end

          def has_no_tag_message?
            has_no_element?('tag-message-content')
          end

          def click_release_link
            click_element('release-link')
          end
        end
      end
    end
  end
end
