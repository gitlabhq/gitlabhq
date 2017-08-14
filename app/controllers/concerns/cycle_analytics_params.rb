module CycleAnalyticsParams
  extend ActiveSupport::Concern

  def options(params)
    @options ||= { from: start_date(params), current_user: current_user }
  end

  def start_date(params)
    case params[:start_date]
    when '7'
      7.days.ago
    when '30'
      30.days.ago
    else
      90.days.ago
    end
  end
end
