module IssuesAction
  extend ActiveSupport::Concern
  include IssuableCollections

  def issues
    @label = issues_finder.labels.first

    @issues = issues_collection
              .non_archived
              .page(params[:page])

    @collection_type    = "Issue"
    @issuable_meta_data = issuable_meta_data(@issues)

    respond_to do |format|
      format.html
      format.atom { render layout: false }
    end
  end
end
