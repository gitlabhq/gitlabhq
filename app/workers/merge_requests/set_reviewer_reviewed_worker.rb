# frozen_string_literal: true

module MergeRequests
  class SetReviewerReviewedWorker
    include Gitlab::EventStore::Subscriber

    data_consistency :always
    feature_category :code_review_workflow
    urgency :low
    idempotent!

    def handle_event(event)
      current_user_id = event.data[:current_user_id]
      merge_request_id = event.data[:merge_request_id]
      current_user = User.find_by_id(current_user_id)
      merge_request = MergeRequest.find_by_id(merge_request_id)

      if !current_user
        logger.info(structured_payload(message: 'Current user not found.', current_user_id: current_user_id))
      elsif !merge_request
        logger.info(structured_payload(message: 'Merge request not found.', merge_request_id: merge_request_id))
      else
        project = merge_request.source_project

        ::MergeRequests::MarkReviewerReviewedService.new(project: project, current_user: current_user)
          .execute(merge_request)
      end
    end
  end
end
