# frozen_string_literal: true

module QA
  module Page
    module Label
      class Index < Page::Base
        include Component::LazyLoader

        view 'app/views/shared/labels/_nav.html.haml' do
          element :label_create_new
        end

        view 'app/views/shared/empty_states/_labels.html.haml' do
          element :label_svg
        end

        view 'app/views/shared/empty_states/_priority_labels.html.haml' do
          element :label_svg
        end

        def click_new_label_button
          # The 'labels.svg' takes a fraction of a second to load after which the "New label" button shifts up a bit
          # This can cause webdriver to miss the hit so we wait for the svg to load (implicitly with has_element?)
          # before clicking the button.
          within_element(:label_svg) do
            has_element?(:js_lazy_loaded)
          end

          click_element :label_create_new
        end
      end
    end
  end
end
