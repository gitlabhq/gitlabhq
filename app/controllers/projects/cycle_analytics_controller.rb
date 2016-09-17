class Projects::CycleAnalyticsController < Projects::ApplicationController
  include CycleAnalyticsHelper

  before_action :authorize_read_cycle_analytics!

  def show
    @cycle_analytics = CycleAnalytics.new(@project, from: parse_start_date)

    respond_to do |format|
      format.html
      format.json { render json: cycle_analytics_json(@cycle_analytics) }
    end
  end

  private

  def parse_start_date
    case cycle_analytics_params[:start_date]
    when '30' then 30.days.ago
    when '90' then 90.days.ago
    else 90.days.ago
    end
  end

  def cycle_analytics_params
    return {} unless params[:cycle_analytics].present?

    { start_date: params[:cycle_analytics][:start_date] }
  end
end
