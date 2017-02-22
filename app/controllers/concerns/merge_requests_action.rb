module MergeRequestsAction
  extend ActiveSupport::Concern
  include IssuableCollections

  def merge_requests
    @label = merge_requests_finder.labels.first

    @merge_requests = merge_requests_collection
                      .page(params[:page])

    @collection_type    = "MergeRequest"
    @issuable_meta_data = issuable_meta_data(@merge_requests)
  end

  private

  def filter_params
    super.merge(non_archived: true)
  end
end
