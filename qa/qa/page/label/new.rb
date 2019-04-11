# frozen_string_literal: true

module QA
  module Page
    module Label
      class New < Page::Base
        view 'app/views/shared/labels/_form.html.haml' do
          element :label_title
          element :label_description
          element :label_color
          element :label_create_button
        end

        def click_label_create_button
          click_element :label_create_button
        end

        def fill_title(title)
          fill_element :label_title, title
        end

        def fill_description(description)
          fill_element :label_description, description
        end

        def fill_color(color)
          fill_element :label_color, color
        end
      end
    end
  end
end
