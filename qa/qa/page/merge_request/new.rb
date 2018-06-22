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

        view 'app/views/projects/merge_requests/creations/_new_compare.html.haml' do
          element :source_branch_dropdown, /dropdown_toggle.*Select source branch"/
          element :compare_branches_and_continue, "submit 'Compare branches and continue'"
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

        def select_source_branch(branch_name)
          find('.dropdown-toggle-text', text: 'Select source branch').click
          click_link branch_name
        end

        def compare_branches_and_continue
          click_on 'Compare branches and continue'
        end
      end
    end
  end
end
