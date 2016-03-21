module MergeRequestsAction
  extend ActiveSupport::Concern

  def merge_requests
    @merge_requests = get_merge_requests_collection.non_archived
    @merge_requests = @merge_requests.page(params[:page])
    @merge_requests = @merge_requests.preload(:author, :target_project)

    @label = @issuable_finder.labels.first
  end
end
