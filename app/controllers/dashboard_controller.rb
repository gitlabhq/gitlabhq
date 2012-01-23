class DashboardController < ApplicationController
  respond_to :html

  def index
    @projects = current_user.projects.all
    @active_projects = @projects.select(&:repo_exists?).select(&:last_activity_date_cached).sort_by(&:last_activity_date_cached).reverse
  end

  # Get authored or assigned open merge requests
  def merge_requests
    @projects = current_user.projects.all
    @merge_requests = MergeRequest.where("author_id = :id or assignee_id = :id", :id => current_user.id).opened.order("created_at DESC").limit(40)
  end

  # Get only assigned issues
  def issues
    @projects = current_user.projects.all
    @user   = current_user
    @issues = current_user.assigned_issues.opened.order("created_at DESC").limit(40)

    @issues = @issues.includes(:author, :project)

    respond_to do |format|
      format.html
      format.atom { render :layout => false }
    end
  end
end
