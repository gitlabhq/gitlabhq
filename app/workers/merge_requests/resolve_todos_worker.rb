# frozen_string_literal: true

class MergeRequests::ResolveTodosWorker
  include ApplicationWorker

  sidekiq_options retry: 3

  feature_category :code_review
  urgency :high
  deduplicate :until_executed
  idempotent!

  def perform(merge_request_id, user_id)
    merge_request = MergeRequest.find(merge_request_id)
    user = User.find(user_id)

    MergeRequests::ResolveTodosService.new(merge_request, user).execute
  rescue ActiveRecord::RecordNotFound
  end
end
