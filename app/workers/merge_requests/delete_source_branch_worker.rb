# frozen_string_literal: true

class MergeRequests::DeleteSourceBranchWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :code_review_workflow
  urgency :high
  idempotent!

  def perform(merge_request_id, source_branch_sha, user_id)
    merge_request = MergeRequest.find(merge_request_id)
    user = User.find(user_id)

    # Source branch changed while it's being removed
    return if merge_request.source_branch_sha != source_branch_sha

    ::MergeRequests::RetargetChainService.new(project: merge_request.source_project, current_user: user)
            .execute(merge_request)

    ::Projects::DeleteBranchWorker.new.perform(merge_request.source_project.id, user_id, merge_request.source_branch)
  rescue ActiveRecord::RecordNotFound
  end
end
