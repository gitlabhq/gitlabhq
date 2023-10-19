# frozen_string_literal: true

module QA
  module Page
    module Label
      class New < Page::Base
        view 'app/views/shared/labels/_form.html.haml' do
          element 'label-title-field'
          element 'label-description-field'
          element 'label-color-field'
          element 'label-create-button'
        end

        def click_label_create_button
          click_element('label-create-button')
        end

        def fill_title(title)
          fill_element('label-title-field', title)
        end

        def fill_description(description)
          fill_element('label-description-field', description)
        end

        def fill_color(color)
          fill_element('label-color-field', color)
        end
      end
    end
  end
end
