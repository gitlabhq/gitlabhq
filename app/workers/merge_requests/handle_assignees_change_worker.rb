# frozen_string_literal: true

class MergeRequests::HandleAssigneesChangeWorker
  include ApplicationWorker

  feature_category :code_review
  urgency :high
  deduplicate :until_executed
  idempotent!

  def perform(merge_request_id, user_id, old_assignee_ids, options = {})
    merge_request = MergeRequest.find(merge_request_id)
    user = User.find(user_id)

    old_assignees = User.id_in(old_assignee_ids)

    ::MergeRequests::HandleAssigneesChangeService
      .new(merge_request.target_project, user)
      .execute(merge_request, old_assignees, options)
  rescue ActiveRecord::RecordNotFound
  end
end
