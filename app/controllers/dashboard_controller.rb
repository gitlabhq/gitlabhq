class DashboardController < ApplicationController
  respond_to :html

  before_filter :load_projects
  before_filter :event_filter, only: :show

  def show
    @groups = current_user.authorized_groups
    @has_authorized_projects = @projects.count > 0
    @teams = current_user.authorized_teams
    @projects_count = @projects.count
    @projects = @projects.limit(20)

    @events = Event.in_projects(current_user.authorized_projects.pluck(:id))
    @events = @event_filter.apply_filter(@events)
    @events = @events.limit(20).offset(params[:offset] || 0)

    @last_push = current_user.recent_push

    respond_to do |format|
      format.html
      format.js
      format.atom { render layout: false }
    end
  end

  def projects
    @projects = case params[:scope]
                when 'personal' then
                  @projects.personal(current_user)
                when 'joined' then
                  @projects.joined(current_user)
                else
                  @projects
                end

    @projects = @projects.page(params[:page]).per(30)
  end

  # Get authored or assigned open merge requests
  def merge_requests
    @merge_requests = current_user.cared_merge_requests
    @merge_requests = FilterContext.new(@merge_requests, params).execute
    @merge_requests = @merge_requests.recent.page(params[:page]).per(20)
  end

  # Get only assigned issues
  def issues
    @issues = current_user.assigned_issues
    @issues = FilterContext.new(@issues, params).execute
    @issues = @issues.recent.page(params[:page]).per(20)
    @issues = @issues.includes(:author, :project)

    respond_to do |format|
      format.html
      format.atom { render layout: false }
    end
  end

  protected

  def load_projects
    @projects = current_user.authorized_projects.sorted_by_activity
  end

  def event_filter
    filters = cookies['event_filter'].split(',') if cookies['event_filter']
    @event_filter ||= EventFilter.new(filters)
  end
end
