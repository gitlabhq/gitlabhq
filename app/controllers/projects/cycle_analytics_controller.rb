class Projects::CycleAnalyticsController < Projects::ApplicationController
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::TextHelper
  include CycleAnalyticsParams

  before_action :whitelist_query_limiting, only: [:show]
  before_action :authorize_read_cycle_analytics!

  def show
    @cycle_analytics = ::CycleAnalytics.new(@project, options(cycle_analytics_params))

    @cycle_analytics_no_data = @cycle_analytics.no_stats?

    respond_to do |format|
      format.html
      format.json { render json: cycle_analytics_json }
    end
  end

  private

  def cycle_analytics_params
    return {} unless params[:cycle_analytics].present?

    params[:cycle_analytics].permit(:start_date)
  end

  def cycle_analytics_json
    {
      summary: @cycle_analytics.summary,
      stats: @cycle_analytics.stats,
      permissions: @cycle_analytics.permissions(user: current_user)
    }
  end

  def whitelist_query_limiting
    Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-ce/issues/42671')
  end
end
