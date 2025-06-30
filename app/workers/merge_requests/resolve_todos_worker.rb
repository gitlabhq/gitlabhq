# frozen_string_literal: true

class MergeRequests::ResolveTodosWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :code_review_workflow
  urgency :high
  deduplicate :until_executed
  idempotent!

  def perform(merge_request_id, user_id)
    merge_request = MergeRequest.find_by_id(merge_request_id)
    user = User.find_by_id(user_id)

    return unless merge_request && user

    MergeRequests::ResolveTodosService.new(merge_request, user).execute
  end
end
