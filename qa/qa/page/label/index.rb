# frozen_string_literal: true

module QA
  module Page
    module Label
      class Index < Page::Base
        include Component::LazyLoader

        view 'app/views/shared/labels/_nav.html.haml' do
          element :create_new_label_button
        end

        view 'app/views/shared/empty_states/_labels.html.haml' do
          element :label_svg_content
        end

        view 'app/views/shared/empty_states/_priority_labels.html.haml' do
          element :label_svg_content
        end

        def click_new_label_button
          # The 'labels.svg' takes a fraction of a second to load after which the "New label" button shifts up a bit
          # This can cause webdriver to miss the hit so we wait for the svg to load (implicitly with has_element?)
          # before clicking the button.
          within_element(:label_svg_content) do
            has_element?(:js_lazy_loaded_content)
          end

          click_element :create_new_label_button
        end
      end
    end
  end
end
