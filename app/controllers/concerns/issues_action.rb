module IssuesAction
  extend ActiveSupport::Concern

  def issues
    @issues = get_issues_collection
    @issues = @issues.page(params[:page]).per(ApplicationController::PER_PAGE)
    @issues = @issues.preload(:author, :project)

    respond_to do |format|
      format.html
      format.atom { render layout: false }
    end
  end
end
