# frozen_string_literal: true

module MergeRequests
  class ProcessDraftNotePublishedWorker
    include Gitlab::EventStore::Subscriber

    data_consistency :always
    feature_category :code_review_workflow
    urgency :low
    defer_on_database_health_signal :gitlab_main, [:todos], 1.minute
    idempotent!

    def handle_event(event)
      current_user = User.find_by_id(event.data[:current_user_id])
      unless current_user
        logger.info(structured_payload(message: 'Current user not found.',
          current_user_id: event.data[:current_user_id]))
        return
      end

      merge_request = MergeRequest.find_by_id(event.data[:merge_request_id])
      unless merge_request
        logger.info(structured_payload(message: 'Merge request not found.',
          merge_request_id: event.data[:merge_request_id]))
        return
      end

      TodoService.new.new_review(merge_request, current_user)

      review = merge_request.reviews.find_by_id(event.data[:review_id])
      NotificationService.new.new_review(review) if review

      return unless merge_request.discussions_resolved?

      NotificationService.new.resolve_all_discussions(merge_request, current_user)
    end
  end
end
