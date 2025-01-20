# frozen_string_literal: true

module QA
  module Page
    module Import
      class ReviewReassignment < Page::Base
        view 'app/views/import/source_users/show.html.haml' do
          element 'approve-reassignment-button'
        end

        def click_approve_reassignment
          find_element('approve-reassignment-button').click
        end
      end
    end
  end
end
