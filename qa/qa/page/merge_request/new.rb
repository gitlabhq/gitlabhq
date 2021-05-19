# frozen_string_literal: true

module QA
  module Page
    module MergeRequest
      class New < Page::Issuable::New
        view 'app/views/shared/issuable/_form.html.haml' do
          element :issuable_create_button, required: true
        end

        view 'app/views/shared/form_elements/_description.html.haml' do
          element :issuable_form_description
        end

        view 'app/views/projects/merge_requests/show.html.haml' do
          element :diffs_tab
        end

        view 'app/assets/javascripts/diffs/components/diff_file_header.vue' do
          element :file_name_content
        end

        def create_merge_request
          click_element(:issuable_create_button, Page::MergeRequest::Show)
        end

        def has_description?(description)
          has_element?(:issuable_form_description, text: description)
        end

        def click_diffs_tab
          click_element(:diffs_tab)
          click_element(:dismiss_popover_button) if has_element?(:dismiss_popover_button, wait: 1)
        end

        def has_file?(file_name)
          has_element?(:file_name_content, text: file_name)
        end
      end
    end
  end
end

QA::Page::MergeRequest::New.prepend_mod_with('Page::MergeRequest::New', namespace: QA)
