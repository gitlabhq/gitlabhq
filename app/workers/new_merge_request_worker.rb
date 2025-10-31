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
    context = { merge_request_id: merge_request_id, user_id: user_id }
    xp = Labkit::UserExperienceSli.resume(:create_merge_request, **context)

    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/337182')

    xp.error!('merge request not ready') unless objects_found?(merge_request_id, user_id)
    xp.error!('merge request is already prepared') if issuable&.prepared?
    return xp.complete(**context) if xp.has_error?

    MergeRequests::AfterCreateService
      .new(project: issuable.target_project, current_user: user)
      .execute(issuable)

    xp.complete(**context)
  end

  def issuable_class
    MergeRequest
  end
end

NewMergeRequestWorker.prepend_mod
