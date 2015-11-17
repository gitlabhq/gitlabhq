class DashboardController < Dashboard::ApplicationController
  before_action :event_filter, only: :activity
  before_action :projects, only: [:issues, :merge_requests]

  respond_to :html

  def merge_requests
    @merge_requests = get_merge_requests_collection
    @merge_requests = @merge_requests.page(params[:page]).per(PER_PAGE)
    @merge_requests = @merge_requests.preload(:author, :target_project)
  end

  def issues
    @issues = get_issues_collection
    @issues = @issues.page(params[:page]).per(PER_PAGE)
    @issues = @issues.preload(:author, :project)

    respond_to do |format|
      format.html
      format.atom { render layout: false }
    end
  end

  def activity
    @last_push = current_user.recent_push

    respond_to do |format|
      format.html

      format.json do
        load_events
        pager_json("events/_events", @events.count)
      end
    end
  end

  protected

  def load_events
    project_ids =
      if params[:filter] == "starred"
        current_user.starred_projects
      else
        current_user.authorized_projects
      end.pluck(:id)

    @events = Event.in_projects(project_ids)
    @events = @event_filter.apply_filter(@events).with_associations
    @events = @events.limit(20).offset(params[:offset] || 0)
  end

  def projects
    @projects ||= current_user.authorized_projects.sorted_by_activity.non_archived
  end
end
