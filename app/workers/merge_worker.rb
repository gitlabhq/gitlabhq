class MergeWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform(merge_request_id, current_user_id, params)
    params = params.with_indifferent_access
    current_user = User.find(current_user_id)
    merge_request = MergeRequest.find(merge_request_id)

    result = MergeRequests::MergeService.new(merge_request.target_project, current_user).
      execute(merge_request, params[:commit_message])

    if result[:status] == :success && params[:should_remove_source_branch].present?
      DeleteBranchService.new(merge_request.source_project, current_user).
        execute(merge_request.source_branch)

      merge_request.source_project.repository.expire_branch_names
    end

    result
  end
end
