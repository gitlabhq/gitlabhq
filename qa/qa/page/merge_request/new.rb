module QA
  module Page
    module MergeRequest
      class New < Page::Base
        view 'app/views/shared/issuable/_form.html.haml' do
          element :issuable_create_button
        end

        view 'app/views/shared/issuable/form/_title.html.haml' do
          element :issuable_form_title
        end

        view 'app/views/shared/form_elements/_description.html.haml' do
          element :issuable_form_description
        end

        def create_merge_request
          click_element :issuable_create_button
        end

        def fill_title(title)
          fill_element :issuable_form_title, title
        end

        def fill_description(description)
          fill_element :issuable_form_description, description
        end
      end
    end
  end
end
