# frozen_string_literal: true

class NewMergeRequestWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  include NewIssuable

  feature_category :code_review
  urgency :high
  worker_resource_boundary :cpu
  weight 2

  def perform(merge_request_id, user_id)
    return unless objects_found?(merge_request_id, user_id)

    MergeRequests::AfterCreateService
      .new(project: issuable.target_project, current_user: user)
      .execute(issuable)
  end

  def issuable_class
    MergeRequest
  end
end
