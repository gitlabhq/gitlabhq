# frozen_string_literal: true

class MergeRequests::DeleteSourceBranchWorker
  include ApplicationWorker

  sidekiq_options retry: 3

  feature_category :source_code_management
  urgency :high
  idempotent!

  def perform(merge_request_id, source_branch_sha, user_id)
    merge_request = MergeRequest.find(merge_request_id)
    user = User.find(user_id)

    # Source branch changed while it's being removed
    return if merge_request.source_branch_sha != source_branch_sha

    ::Branches::DeleteService.new(merge_request.source_project, user)
      .execute(merge_request.source_branch)

    ::MergeRequests::RetargetChainService.new(project: merge_request.source_project, current_user: user)
      .execute(merge_request)
  rescue ActiveRecord::RecordNotFound
  end
end
