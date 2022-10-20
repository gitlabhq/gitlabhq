# frozen_string_literal: true

module QA
  module Page
    module Project
      module Tag
        class New < Page::Base
          view 'app/views/projects/tags/new.html.haml' do
            element :tag_name_field
            element :tag_message_field
            element :create_tag_button
          end

          def fill_tag_name(text)
            fill_element(:tag_name_field, text)
          end

          def fill_tag_message(text)
            fill_element(:tag_message_field, text)
          end

          def click_create_tag_button
            click_element :create_tag_button
          end
        end
      end
    end
  end
end
