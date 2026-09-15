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
      # Completes the "submit and notify MR review" experience started in the web
      # request (Projects::MergeRequests::DraftsController#publish) and propagated
      # here through the Sidekiq user experience middleware. Completed in an ensure
      # so every exit path is covered without altering this method's return value.
      # On paths where it was never started (API, quick actions, AI reviews), Labkit
      # short-circuits resume/complete on the unstarted experience.
      experience = Labkit::UserExperienceSli.resume(:submit_and_notify_mr_review_ui)

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
      notification_service.new_review(review) if review

      return unless merge_request.discussions_resolved?

      notification_service.resolve_all_discussions(merge_request, current_user)
    ensure
      experience&.complete(notes_published: true)
    end

    private

    def notification_service
      @notification_service ||= NotificationService.new
    end
  end
end
