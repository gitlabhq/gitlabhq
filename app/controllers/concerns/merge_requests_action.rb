module MergeRequestsAction
  extend ActiveSupport::Concern
  include IssuableCollections

  def merge_requests
    @finder_type = MergeRequestsFinder
    @label = finder.labels.first

    @merge_requests = issuables_collection.page(params[:page])

    @issuable_meta_data = issuable_meta_data(@merge_requests, collection_type)
  end

  private

  def filter_params
    super.merge(non_archived: true)
  end
end
