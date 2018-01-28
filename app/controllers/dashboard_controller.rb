class DashboardController < Dashboard::ApplicationController
  include IssuesAction
  include MergeRequestsAction

  before_action :event_filter, only: :activity
  before_action :projects, only: [:issues, :merge_requests]
  before_action :set_show_full_reference, only: [:issues, :merge_requests]

  respond_to :html

  def activity
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
    projects =
      if params[:filter] == "starred"
        ProjectsFinder.new(current_user: current_user, params: { starred: true }).execute
      else
        current_user.authorized_projects
      end

    @events = EventCollection
      .new(projects, offset: params[:offset].to_i, filter: @event_filter)
      .to_a

    Events::RenderService.new(current_user).execute(@events)
  end

  def set_show_full_reference
    @show_full_reference = true
  end
end
