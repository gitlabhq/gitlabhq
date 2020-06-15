# frozen_string_literal: true

module QA
  module Page
    module MergeRequest
      class New < Page::Issuable::New
        view 'app/views/shared/issuable/_form.html.haml' do
          element :issuable_create_button
        end

        def create_merge_request
          click_element :issuable_create_button, Page::MergeRequest::Show
        end
      end
    end
  end
end

QA::Page::MergeRequest::New.prepend_if_ee('QA::EE::Page::MergeRequest::New')
