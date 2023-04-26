# frozen_string_literal: true

class Projects::Analytics::CycleAnalytics::SummaryController < Projects::ApplicationController
  extend ::Gitlab::Utils::Override
  include CycleAnalyticsParams

  respond_to :json

  feature_category :planning_analytics

  before_action :authorize_read_cycle_analytics!

  urgency :low

  def show
    render json: project_level.summary
  end

  private

  def namespace
    @project.project_namespace
  end

  def project_level
    @project_level ||= Analytics::CycleAnalytics::ProjectLevel.new(project: @project, options: options(allowed_params))
  end

  def allowed_params
    request_params.to_data_collector_params
  end
end

Projects::Analytics::CycleAnalytics::SummaryController.prepend_mod_with('Projects::Analytics::CycleAnalytics::SummaryController')
