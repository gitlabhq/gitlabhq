# frozen_string_literal: true

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

        view 'app/views/shared/issuable/_label_dropdown.html.haml' do
          element :issuable_label
        end

        view 'app/views/shared/issuable/form/_metadata_issuable_assignee.html.haml' do
          element :assign_to_me_link
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

        def select_label(label)
          click_element :issuable_label

          click_link label.title
        end

        def assign_to_me
          click_element :assign_to_me_link
        end
      end
    end
  end
end

QA::Page::MergeRequest::New.prepend_if_ee('QA::EE::Page::MergeRequest::New')
