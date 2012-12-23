class DashboardController < ApplicationController
  respond_to :html

  before_filter :projects
  before_filter :event_filter, only: :index

  def index
    @groups = current_user.authorized_groups

    @has_authorized_projects = @projects.count > 0

    @projects = case params[:scope]
                when 'personal' then
                  @projects.personal(current_user)
                when 'joined' then
                  @projects.joined(current_user)
                else
                  @projects
                end

    @projects = @projects.page(params[:page]).per(30)

    @events = Event.in_projects(current_user.project_ids)
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
    @merge_requests = current_user.cared_merge_requests
    @merge_requests = dashboard_filter(@merge_requests)
    @merge_requests = @merge_requests.recent.page(params[:page]).per(20)
  end

  # Get only assigned issues
  def issues
    @issues = current_user.assigned_issues
    @issues = dashboard_filter(@issues)
    @issues = @issues.recent.page(params[:page]).per(20)
    @issues = @issues.includes(:author, :project)

    respond_to do |format|
      format.html
      format.atom { render layout: false }
    end
  end

  protected

  def projects
    @projects = current_user.authorized_projects.sorted_by_activity
  end

  def event_filter
    @event_filter ||= EventFilter.new(params[:event_filter])
  end

  def dashboard_filter items
    if params[:project_id]
      items = items.where(project_id: params[:project_id])
    end

    if params[:search].present?
      items = items.search(params[:search])
    end

    case params[:status]
    when 'closed'
      items.closed
    when 'all'
      items
    else
      items.opened
    end
  end
end
