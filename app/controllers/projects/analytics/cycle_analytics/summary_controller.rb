# frozen_string_literal: true

class Projects::Analytics::CycleAnalytics::SummaryController < Projects::ApplicationController
  include CycleAnalyticsParams

  respond_to :json

  feature_category :planning_analytics

  before_action :authorize_read_cycle_analytics!

  def show
    render json: project_level.summary
  end

  private

  def project_level
    @project_level ||= Analytics::CycleAnalytics::ProjectLevel.new(project: @project, options: options(allowed_params))
  end

  def allowed_params
    params.permit(:created_after, :created_before)
  end
end

Projects::Analytics::CycleAnalytics::SummaryController.prepend_mod_with('Projects::Analytics::CycleAnalytics::SummaryController')
