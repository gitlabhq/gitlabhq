# frozen_string_literal: true

class NewMergeRequestWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include NewIssuable

  feature_category :source_code_management
  urgency :high
  worker_resource_boundary :cpu
  weight 2

  def perform(merge_request_id, user_id)
    return unless objects_found?(merge_request_id, user_id)

    MergeRequests::AfterCreateService
      .new(issuable.target_project, user)
      .execute(issuable)
  end

  def issuable_class
    MergeRequest
  end
end
