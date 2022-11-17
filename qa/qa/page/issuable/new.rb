# frozen_string_literal: true

module QA
  module Page
    module Issuable
      class New < Page::Base
        view 'app/views/shared/issuable/form/_title.html.haml' do
          element :issuable_form_title_field
        end

        view 'app/views/shared/form_elements/_description.html.haml' do
          element :issuable_form_description_field
        end

        view 'app/assets/javascripts/sidebar/components/milestone/milestone_dropdown.vue' do
          element :issuable_milestone_dropdown
        end

        view 'app/views/shared/issuable/_label_dropdown.html.haml' do
          element :issuable_label_dropdown
        end

        view 'app/views/shared/issuable/form/_metadata_issuable_assignee.html.haml' do
          element :assign_to_me_link
        end

        view 'app/views/shared/issuable/form/_template_selector.html.haml' do
          element :template_dropdown
        end

        def fill_title(title)
          fill_element :issuable_form_title_field, title
        end

        def fill_description(description)
          fill_element :issuable_form_description_field, description
        end

        def choose_milestone(milestone)
          within_element(:issuable_milestone_dropdown) do
            click_button 'Select milestone'
            click_button milestone.title
          end
        end

        def choose_template(template_name)
          click_element :template_dropdown
          within_element(:template_dropdown) do
            click_on template_name
          end
        end

        def select_label(label)
          click_element :issuable_label_dropdown

          click_link label.title

          click_element :issuable_label_dropdown # So that the dropdown goes away(click away action)
        end

        def assign_to_me
          click_element :assign_to_me_link
        end
      end
    end
  end
end
