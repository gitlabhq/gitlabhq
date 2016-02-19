module MergeRequestsAction
  extend ActiveSupport::Concern

  def merge_requests
    @merge_requests = get_merge_requests_collection
    @merge_requests = @merge_requests.page(params[:page]).per(ApplicationController::PER_PAGE)
    @merge_requests = @merge_requests.preload(:author, :target_project)

    @label = @issuable_finder.labels.first
  end
end
