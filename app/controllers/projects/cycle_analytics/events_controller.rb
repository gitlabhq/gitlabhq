class Projects::CycleAnalytics::EventsController < Projects::ApplicationController
  # before_action :authorize_read_cycle_analytics!

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

  def render_events(event_list)
    respond_to do |format|
      format.html
      format.json { render json: { events: event_list } }
    end
  end

  # TODO refactor this
  def start_date
    case events_params[:start_date]
    when '30' then
      30.days.ago
    when '90' then
      90.days.ago
    else
      90.days.ago
    end
  end

  def events
    @events ||= Gitlab::CycleAnalytics::Events.new(project: project, from: start_date)
  end

  def events_params
    return {} unless params[:events].present?

    { start_date: params[:events][:start_date] }
  end
end
