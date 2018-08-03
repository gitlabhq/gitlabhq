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

        view 'app/views/shared/issuable/form/_metadata.html.haml' do
          element :issuable_milestone_dropdown
        end

        view 'app/views/shared/form_elements/_description.html.haml' do
          element :issuable_form_description
        end

        view 'app/views/shared/issuable/_milestone_dropdown.html.haml' do
          element :issuable_dropdown_menu_milestone
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

        def choose_milestone(milestone)
          click_element :issuable_milestone_dropdown
          within_element(:issuable_dropdown_menu_milestone) do
            click_on milestone.title
          end
        end
      end
    end
  end
end
