class MergeWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  def perform(merge_request_id, current_user_id, params)
    current_user = User.find(current_user_id)
    merge_request = MergeRequest.find(merge_request_id)

    MergeRequests::MergeService.new(merge_request.target_project, current_user, params)
      .execute(merge_request)
  end
end
