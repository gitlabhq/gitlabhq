# frozen_string_literal: true

module QA
  module Page
    module Label
      class New < Page::Base
        view 'app/views/shared/labels/_form.html.haml' do
          element :label_title_field
          element :label_description_field
          element :label_color_field
          element :label_create_button
        end

        def click_label_create_button
          click_element :label_create_button
        end

        def fill_title(title)
          fill_element :label_title_field, title
        end

        def fill_description(description)
          fill_element :label_description_field, description
        end

        def fill_color(color)
          fill_element :label_color_field, color
        end
      end
    end
  end
end
