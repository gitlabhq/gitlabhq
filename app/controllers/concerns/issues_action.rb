module IssuesAction
  extend ActiveSupport::Concern
  include IssuableCollections

  def issues
    @label = issues_finder.labels.first

    @issues = issues_collection
              .non_archived
              .preload(:author, :project)
              .page(params[:page])

    @all_issues = all_issues_collection.non_archived

    respond_to do |format|
      format.html
      format.atom { render layout: false }
    end
  end
end
