module MergeRequestsAction
  extend ActiveSupport::Concern
  include IssuableCollections

  def merge_requests
    @label = merge_requests_finder.labels.first

    @merge_requests = merge_requests_collection
                      .non_archived
                      .preload(:author, :target_project)
                      .page(params[:page])
  end
end
