module CycleAnalyticsParams
  extend ActiveSupport::Concern

  def options(params)
    @options ||= { from: start_date(params), current_user: current_user }
  end

  def start_date(params)
    params[:start_date] == '30' ? 30.days.ago : 90.days.ago
  end
end
