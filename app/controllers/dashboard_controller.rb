class DashboardController < ApplicationController
  respond_to :html

  def index
    @projects = current_user.projects.all

    @active_projects = @projects.select(&:last_activity_date).sort_by(&:last_activity_date).reverse

    @merge_requests = MergeRequest.where("author_id = :id or assignee_id = :id", :id => current_user.id).opened.order("created_at DESC").limit(5)

    @user   = current_user
    @issues = current_user.assigned_issues.opened.order("created_at DESC").limit(5)
    @issues = @issues.includes(:author, :project)

    @events = Event.where(:project_id => @projects.map(&:id)).recent.limit(20)
    @last_push = Event.where(:project_id => @projects.map(&:id)).recent.code_push.limit(1).first
  end

  # Get authored or assigned open merge requests
  def merge_requests
    @projects = current_user.projects.all
    @merge_requests = current_user.cared_merge_requests.order("created_at DESC").page(params[:page]).per(20)
  end

  # Get only assigned issues
  def issues
    @projects = current_user.projects.all
    @user   = current_user
    @issues = current_user.assigned_issues.opened.order("created_at DESC").page(params[:page]).per(20)
    @issues = @issues.includes(:author, :project)

    respond_to do |format|
      format.html
      format.atom { render :layout => false }
    end
  end
end
