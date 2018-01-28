module MergeRequestsAction
  extend ActiveSupport::Concern
  include IssuableCollections

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def merge_requests
    @finder_type = MergeRequestsFinder

    @merge_requests = issuables_collection.page(params[:page])

    @issuable_meta_data = issuable_meta_data(@merge_requests, collection_type)
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  private

  def filter_params
    super.merge(non_archived: true)
  end
end
