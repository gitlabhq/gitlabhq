class RebaseWorker
  include ApplicationWorker

  def perform(merge_request_id, current_user_id)
    current_user = User.find(current_user_id)
    merge_request = MergeRequest.find(merge_request_id)

    MergeRequests::RebaseService
      .new(merge_request.source_project, current_user)
      .execute(merge_request)
  end
end
