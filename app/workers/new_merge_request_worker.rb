# frozen_string_literal: true

class NewMergeRequestWorker
  include ApplicationWorker
  include NewIssuable

  data_consistency :always
  sidekiq_options retry: 3

  idempotent!
  deduplicate :until_executed

  feature_category :code_review_workflow
  urgency :high

  worker_resource_boundary :cpu
  weight 2

  def perform(merge_request_id, user_id)
    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/337182')

    return unless objects_found?(merge_request_id, user_id)
    return if issuable.prepared?

    MergeRequests::AfterCreateService
      .new(project: issuable.target_project, current_user: user)
      .execute(issuable)
  end

  def issuable_class
    MergeRequest
  end
end
