# frozen_string_literal: true

module QA
  module Page
    module MergeRequest
      class New < Page::Base
        include QA::Page::Component::Dropdown

        view 'app/assets/javascripts/merge_requests/components/compare_app.vue' do
          element 'compare-dropdown'
        end

        view 'app/assets/javascripts/sidebar/components/milestone/milestone_dropdown.vue' do
          element 'issuable-milestone-dropdown'
        end

        view 'app/views/projects/merge_requests/creations/_new_compare.html.haml' do
          element 'compare-branches-button'
        end

        view 'app/views/shared/form_elements/_description.html.haml' do
          element 'issuable-form-description-field'
        end

        view 'app/views/shared/issuable/_form.html.haml' do
          element 'issuable-create-button', required: true
        end

        view 'app/views/shared/issuable/_label_dropdown.html.haml' do
          element 'issuable-label-dropdown'
        end

        view 'app/views/shared/issuable/form/_metadata_issuable_assignee.html.haml' do
          element 'assign-to-me-link'
        end

        view 'app/views/shared/issuable/form/_template_selector.html.haml' do
          element 'template-dropdown'
        end

        view 'app/views/shared/issuable/form/_title.html.haml' do
          element 'issuable-form-title-field'
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

        def click_compare_branches_and_continue
          click_element('compare-branches-button')
        end

        def create_merge_request
          click_element('issuable-create-button', Page::MergeRequest::Show)
        end

        def select_source_branch(branch)
          click_element('compare-dropdown', 'compare-side': 'source')
          search_and_select(branch)
        end
      end
    end
  end
end

QA::Page::MergeRequest::New.prepend_mod_with('Page::MergeRequest::New', namespace: QA)
