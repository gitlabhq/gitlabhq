class Projects::CycleAnalytics::EventsController < Projects::ApplicationController
  #before_action :authorize_read_cycle_analytics!

  def issues
    respond_to do |format|
      format.html
      format.json { render json: events.issue_events }
    end
  end

  private

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