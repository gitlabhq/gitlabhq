# frozen_string_literal: true

module QA
  module Page
    module Project
      module Tag
        class New < Page::Base
          view 'app/views/projects/tags/new.html.haml' do
            element 'tag-name-field'
            element 'tag-message-field'
            element 'create-tag-button'
          end

          def fill_tag_name(text)
            fill_element('tag-name-field', text)
          end

          def fill_tag_message(text)
            fill_element('tag-message-field', text)
          end

          def click_create_tag_button
            click_element 'create-tag-button'
          end
        end
      end
    end
  end
end
