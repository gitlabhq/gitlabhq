module CycleAnalyticsParams
  extend ActiveSupport::Concern

  def options
    @options ||= { from: start_date(events_params), current_user: current_user }
  end

  def start_date(params)
    params[:start_date] == '30' ? 30.days.ago : 90.days.ago
  end
end
