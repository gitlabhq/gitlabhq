class Dashboard::ProjectsController < Dashboard::ApplicationController
  include ProjectsListing

  before_action :init_filter_and_sort, :load_last_push, :event_filter

  def index
    @projects = filter_listing(current_user.authorized_projects)

    respond_to do |format|
      format.html
      format.atom do
        load_events
        render layout: false
      end
    end
  end

  def starred
    @projects = filter_listing(current_user.starred_projects)
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

  def load_last_push
    @last_push = current_user.recent_push
  end

  def load_events
    @events = Event.in_projects(@projects)
    @events = @event_filter.apply_filter(@events).with_associations
    @events = @events.limit(20).offset(params[:offset] || 0)
  end
end
