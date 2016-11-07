class Projects::CycleAnalytics::EventsController < Projects::ApplicationController
  include CycleAnalyticsParams

  before_action :authorize_read_cycle_analytics!

  def issue
    render_events(events.issue_events)
  end

  def plan
    render_events(events.plan_events)
  end

  def code
    render_events(events.code_events)
  end

  def test
    @opts = { from: start_date(events_params), branch: events_params[:branch_name] }

    render_events(events.test_events)
  end

  def review
    render_events(events.review_events)
  end

  def staging
    render_events(events.staging_events)
  end

  def production
    render_events(events.production_events)
  end

  private

  def render_events(events)
    respond_to do |format|
      format.html
      format.json { render json: { items: events } }
    end
  end

  def events
    @events ||= Gitlab::CycleAnalytics::Events.new(project: project, options: options)
  end

  def options
    @opts ||= { from: start_date(events_params) }
  end

  def events_params
    return {} unless params[:events].present?

    { start_date: params[:events][:start_date], branch_name: params[:events][:branch_name] }
  end
end
