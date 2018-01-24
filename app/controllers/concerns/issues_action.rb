module IssuesAction
  extend ActiveSupport::Concern
  include IssuableCollections

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def issues
    @finder_type = IssuesFinder
    @issues = issuables_collection
              .non_archived
              .page(params[:page])

    @issuable_meta_data = issuable_meta_data(@issues, collection_type)

    respond_to do |format|
      format.html
      format.atom { render layout: 'xml.atom' }
    end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables
end
