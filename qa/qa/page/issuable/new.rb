# frozen_string_literal: true

module QA
  module Page
    module Issuable
      class New < Page::Base
        view 'app/views/shared/issuable/form/_title.html.haml' do
          element 'issuable-form-title-field'
        end

        view 'app/views/shared/form_elements/_description.html.haml' do
          element 'issuable-form-description-field'
        end

        view 'app/assets/javascripts/sidebar/components/milestone/milestone_dropdown.vue' do
          element 'issuable-milestone-dropdown'
        end

        view 'app/views/shared/issuable/_label_dropdown.html.haml' do
          element 'issuable-label-dropdown'
        end

        view 'app/assets/javascripts/sidebar/components/labels/labels_select_widget/dropdown_contents.vue' do
          element 'labels-select-dropdown-contents'
        end

        view 'app/views/shared/issuable/form/_metadata_issuable_assignee.html.haml' do
          element 'assign-to-me-link'
        end

        view 'app/views/shared/issuable/form/_template_selector.html.haml' do
          element 'template-dropdown'
        end

        def fill_title(title)
          fill_element('issuable-form-title-field', title)
        end

        def fill_description(description)
          fill_editor_element('issuable-form-description-field', description)
        end

        def choose_milestone(milestone)
          within_element('issuable-milestone-dropdown') do
            click_button('Select milestone')
            click_button(milestone.title)
          end
        end

        def choose_template(template_name)
          click_element('template-dropdown')
          within_element('template-dropdown') do
            click_on(template_name)
          end
        end

        def select_label(label)
          click_element('issuable-label-dropdown')

          click_on(label.title, match: :prefer_exact)

          click_element('issuable-label-dropdown') # So that the dropdown goes away(click away action)
        end

        def assign_to_me
          click_element('assign-to-me-link')
        end
      end
    end
  end
end
