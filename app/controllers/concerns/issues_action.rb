module IssuesAction
  extend ActiveSupport::Concern

  def issues
    @issues = get_issues_collection.non_archived
    @issues = @issues.page(params[:page]).per(ApplicationController::PER_PAGE)
    @issues = @issues.preload(:author, :project)

    @label = @issuable_finder.labels.first

    respond_to do |format|
      format.html
      format.atom { render layout: false }
    end
  end
end
