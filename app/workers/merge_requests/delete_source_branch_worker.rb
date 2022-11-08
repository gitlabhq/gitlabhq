# frozen_string_literal: true

class MergeRequests::DeleteSourceBranchWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :source_code_management
  urgency :high
  idempotent!

  def perform(merge_request_id, source_branch_sha, user_id)
    merge_request = MergeRequest.find(merge_request_id)
    user = User.find(user_id)

    # Source branch changed while it's being removed
    return if merge_request.source_branch_sha != source_branch_sha

    if Feature.enabled?(:add_delete_branch_worker, merge_request.source_project)
      ::MergeRequests::DeleteBranchWorker.perform_async(merge_request_id, user_id, merge_request.source_branch, true)
    else
      delete_service_result = ::Branches::DeleteService.new(merge_request.source_project, user)
        .execute(merge_request.source_branch)

      if Feature.enabled?(:track_delete_source_errors, merge_request.source_project)
        delete_service_result.track_exception if delete_service_result&.error?
      end

      ::MergeRequests::RetargetChainService.new(project: merge_request.source_project, current_user: user)
        .execute(merge_request)
    end
  rescue ActiveRecord::RecordNotFound
  end
end
