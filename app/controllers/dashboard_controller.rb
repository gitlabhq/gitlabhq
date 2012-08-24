class DashboardController < ApplicationController
  respond_to :html

  before_filter :event_filter, only: :index

  def index
    @groups = Group.where(id: current_user.projects.pluck(:group_id))
    @projects = current_user.projects_sorted_by_activity
    @public_projects = Project.find_all_by_private_flag(false) - @projects
    @projects = @projects.page(params[:page]).per(30)

    @events = Event.recent_for_projects(@projects + @public_projects)
    @events = @event_filter.apply_filter(@events)
    @events = @events.limit(20).offset(params[:offset] || 0)

    @last_push = current_user.recent_push

    respond_to do |format|
      format.html
      format.js
      format.atom { render layout: false }
    end
  end

  # Get authored or assigned open merge requests
  def merge_requests
    @projects = current_user.projects.all
    @merge_requests = current_user.cared_merge_requests.recent.page(params[:page]).per(20)
  end

  # Get only assigned issues
  def issues
    @projects = current_user.projects.all
    @user   = current_user
    @issues = current_user.assigned_issues.opened.recent.page(params[:page]).per(20)
    @issues = @issues.includes(:author, :project)

    respond_to do |format|
      format.html
      format.atom { render layout: false }
    end
  end

  def event_filter
    @event_filter ||= EventFilter.new(params[:event_filter])
  end
end
