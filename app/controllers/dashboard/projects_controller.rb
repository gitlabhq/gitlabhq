class Dashboard::ProjectsController < Dashboard::ApplicationController
  before_action :event_filter

  def index
    @projects = current_user.authorized_projects.sorted_by_activity.non_archived
    @projects = @projects.includes(:namespace)
    @last_push = current_user.recent_push

    respond_to do |format|
      format.html
      format.atom do
        event_filter
        load_events
        render layout: false
      end
    end
  end

  def starred
    @projects = current_user.starred_projects
    @projects = @projects.includes(:namespace, :forked_from_project, :tags)
    @projects = @projects.sort(@sort = params[:sort])
    @groups = []

    respond_to do |format|
      format.html

      format.json do
        load_events
        pager_json("events/_events", @events.count)
      end
    end
  end

  private

  def load_events
    @events = Event.in_projects(@projects.pluck(:id))
    @events = @event_filter.apply_filter(@events).with_associations
    @events = @events.limit(20).offset(params[:offset] || 0)
  end
end
