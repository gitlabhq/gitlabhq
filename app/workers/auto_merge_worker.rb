class AutoMergeWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform(merge_request_id, current_user_id, params)
    params = params.with_indifferent_access
    current_user = User.find(current_user_id)
    merge_request = MergeRequest.find(merge_request_id)
    merge_request.should_remove_source_branch = params[:should_remove_source_branch]
    merge_request.automerge!(current_user, params[:commit_message])
  end
end
