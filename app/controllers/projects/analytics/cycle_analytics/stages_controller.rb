# frozen_string_literal: true

class Projects::Analytics::CycleAnalytics::StagesController < Projects::ApplicationController
  respond_to :json

  feature_category :planning_analytics

  before_action :authorize_read_cycle_analytics!
  before_action :only_default_value_stream_is_allowed!

  def index
    result = list_service.execute

    if result.success?
      render json: cycle_analytics_configuration(result.payload[:stages])
    else
      render json: { message: result.message }, status: result.http_status
    end
  end

  private

  def only_default_value_stream_is_allowed!
    render_404 if params[:value_stream_id] != Analytics::CycleAnalytics::Stages::BaseService::DEFAULT_VALUE_STREAM_NAME
  end

  def value_stream
    Analytics::CycleAnalytics::ProjectValueStream.build_default_value_stream(@project)
  end

  def list_params
    { value_stream: value_stream }
  end

  def list_service
    Analytics::CycleAnalytics::Stages::ListService.new(parent: @project, current_user: current_user, params: list_params)
  end

  def cycle_analytics_configuration(stages)
    stage_presenters = stages.map { |s| ::Analytics::CycleAnalytics::StagePresenter.new(s) }

    Analytics::CycleAnalytics::ConfigurationEntity.new(stages: stage_presenters)
  end
end
