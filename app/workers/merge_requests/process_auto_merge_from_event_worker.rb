# frozen_string_literal: true

module MergeRequests
  class ProcessAutoMergeFromEventWorker
    include Gitlab::EventStore::Subscriber

    data_consistency :always
    feature_category :continuous_delivery
    idempotent!

    # The difference with this worker and AutoMergeProcessWorker is that this will
    # handle the execution from the event store code
    def handle_event(event)
      merge_request_id = event.data[:merge_request_id]
      merge_request = MergeRequest.find_by_id(merge_request_id)

      unless merge_request
        logger.info(structured_payload(message: 'Merge request not found.', merge_request_id: merge_request_id))
        return
      end

      AutoMergeService.new(merge_request.project, merge_request.merge_user)
                      .process(merge_request)
    end
  end
end
