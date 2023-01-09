# frozen_string_literal: true

module MergeRequests
  class CreateApprovalNoteWorker
    include Gitlab::EventStore::Subscriber

    data_consistency :always
    feature_category :code_review_workflow
    urgency :low
    idempotent!

    def handle_event(event)
      current_user_id = event.data[:current_user_id]
      merge_request_id = event.data[:merge_request_id]
      current_user = User.find_by_id(current_user_id)

      unless current_user
        logger.info(structured_payload(message: 'Current user not found.', current_user_id: current_user_id))
        return
      end

      merge_request = MergeRequest.find_by_id(merge_request_id)

      unless merge_request
        logger.info(structured_payload(message: 'Merge request not found.', merge_request_id: merge_request_id))
        return
      end

      SystemNoteService.approve_mr(merge_request, current_user)
    end
  end
end
