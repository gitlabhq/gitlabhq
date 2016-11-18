module CycleAnalyticsParams
  extend ActiveSupport::Concern

  def start_date(params)
    params[:start_date] == '30' ? 30.days.ago : 90.days.ago
  end
end
