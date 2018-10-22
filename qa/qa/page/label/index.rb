module QA
  module Page
    module Label
      class Index < Page::Base
        view 'app/views/projects/labels/index.html.haml' do
          element :label_create_new
        end

        def go_to_new_label
          click_element :label_create_new
        end
      end
    end
  end
end
