class Projects::CycleAnalytics::EventsController < Projects::ApplicationController
  # TODO: fix authorization
  # before_action :authorize_read_cycle_analytics!

  # TODO: refactor +event_hash+

  def issue
    render_events(issues: events.issue_events)
  end

  def plan
    render_events(commits: events.plan_events)
  end

  def code
    render_events(merge_requests: events.code_events)
  end

  def test
    render_events(builds: events.test_events)
  end

  def review
    render_events(merge_requests: events.review_events)
  end

  def staging
    render_events(builds: events.staging_events)
  end

  def production
    render_events(issues: events.production_events)
  end

  private

  def render_events(event_hash)
    respond_to do |format|
      format.html
      format.json { render json: event_hash }
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
