# frozen_string_literal: true

class MergeRequests::AssigneesChangeWorker
  include ApplicationWorker

  sidekiq_options retry: 3

  feature_category :source_code_management
  urgency :high
  deduplicate :until_executed
  idempotent!

  def perform(merge_request_id, user_id, old_assignee_ids)
    merge_request = MergeRequest.find(merge_request_id)
    current_user = User.find(user_id)

    # if a user was added and then removed, or removed and then added
    # while waiting for this job to run, assume that nothing happened.
    users = User.id_in(old_assignee_ids - merge_request.assignee_ids)

    return if users.blank?

    ::MergeRequests::HandleAssigneesChangeService
      .new(project: merge_request.target_project, current_user: current_user)
      .execute(merge_request, users, execute_hooks: true)
  rescue ActiveRecord::RecordNotFound
  end
end
