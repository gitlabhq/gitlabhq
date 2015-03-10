class DashboardController < ApplicationController
  respond_to :html

  before_filter :load_projects, except: [:projects]
  before_filter :event_filter, only: :show

  def show
    @projects = @projects.includes(:namespace)
    @last_push = current_user.recent_push

    respond_to do |format|
      format.html

      format.json do
        load_events
        pager_json("events/_events", @events.count)
      end

      format.atom do
        load_events
        render layout: false
      end
    end
  end

  def merge_requests
    @merge_requests = get_merge_requests_collection
    @merge_requests = @merge_requests.page(params[:page]).per(20)
    @merge_requests = @merge_requests.preload(:author, :target_project)
  end

  def issues
    @issues = get_issues_collection
    @issues = @issues.page(params[:page]).per(20)
    @issues = @issues.preload(:author, :project)

    respond_to do |format|
      format.html
      format.atom { render layout: false }
    end
  end

  protected

  def load_projects
    @projects = current_user.authorized_projects.sorted_by_activity.non_archived
  end

  def load_events
    @events = Event.in_projects(current_user.authorized_projects.pluck(:id))
    @events = @event_filter.apply_filter(@events).with_associations
    @events = @events.limit(20).offset(params[:offset] || 0)
  end
end
