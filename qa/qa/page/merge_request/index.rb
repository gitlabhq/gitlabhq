# frozen_string_literal: true

module QA
  module Page
    module MergeRequest
      class Index < Page::Base
        view 'app/views/shared/empty_states/_merge_requests.html.haml' do
          element 'new-merge-request-button'
        end

        def click_new_merge_request
          click_element('new-merge-request-button')
        end
      end
    end
  end
end
