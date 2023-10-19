# frozen_string_literal: true

module QA
  module Page
    module Modal
      class DeleteIssue < Base
        view 'app/assets/javascripts/issues/show/components/delete_issue_modal.vue' do
          element 'confirm-delete-issue-button', required: true
        end

        def confirm_delete_issue
          click_element('confirm-delete-issue-button')
        end
      end
    end
  end
end
