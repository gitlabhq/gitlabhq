class Projects::CycleAnalyticsController < Projects::ApplicationController
  def show
    @cycle_analytics = CycleAnalytics.new
  end
end
