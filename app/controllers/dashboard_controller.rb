class DashboardController < ApplicationController
  respond_to :html

  def index
    @projects = current_user.projects.includes(:events).order("events.created_at DESC")
    @projects = @projects.page(params[:page]).per(40)

    @events = Event.where(:project_id => current_user.projects.map(&:id)).recent.limit(20)

    @last_push = current_user.recent_push

    respond_to do |format|
      format.html
      format.atom { render :layout => false }
    end
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
