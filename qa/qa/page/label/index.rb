module QA
  module Page
    module Label
      class Index < Page::Base
        view 'app/views/projects/labels/index.html.haml' do
          element :label_create_new
        end

        view 'app/views/shared/empty_states/_labels.html.haml' do
          element :label_svg
        end

        def go_to_new_label
          # The 'labels.svg' takes a fraction of a second to load after which the "New label" button shifts up a bit
          # This can cause webdriver to miss the hit so we wait for the svg to load (implicitly with has_css?)
          # before clicking the button.
          within_element(:label_svg) do
            has_css?('.js-lazy-loaded')
          end

          click_element :label_create_new
        end
      end
    end
  end
end
