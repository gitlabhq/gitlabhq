# frozen_string_literal: true

class MergeRequests::HandleAssigneesChangeWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :code_review_workflow
  urgency :high
  deduplicate :until_executed
  idempotent!

  def perform(merge_request_id, user_id, old_assignee_ids, options = {})
    merge_request = MergeRequest.find_by_id(merge_request_id)
    user = User.find_by_id(user_id)

    return unless merge_request && user

    old_assignees = User.id_in(old_assignee_ids)

    ::MergeRequests::HandleAssigneesChangeService
      .new(project: merge_request.target_project, current_user: user)
      .execute(merge_request, old_assignees, options)
  end
end
