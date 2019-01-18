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
          wait(reload: false) do
            within_element(:label_svg) do
              has_css?('.js-lazy-loaded')
            end
          end

          click_element :label_create_new
        end
      end
    end
  end
end
