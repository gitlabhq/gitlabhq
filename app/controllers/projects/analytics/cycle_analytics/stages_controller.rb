# frozen_string_literal: true

class Projects::Analytics::CycleAnalytics::StagesController < Projects::ApplicationController
  include ::Analytics::CycleAnalytics::StageActions
  include Gitlab::Utils::StrongMemoize
  extend ::Gitlab::Utils::Override

  respond_to :json

  feature_category :planning_analytics

  before_action :authorize_read_cycle_analytics!
  before_action :only_default_value_stream_is_allowed!
  before_action :authorize_stage!, only: [:median, :count, :average, :records]

  urgency :low

  private

  override :parent
  def parent
    @project
  end

  override :value_stream_class
  def value_stream_class
    Analytics::CycleAnalytics::ProjectValueStream
  end

  override :cycle_analytics_configuration
  def cycle_analytics_configuration(stages)
    super(stages.select { |stage| permitted_stage?(stage) })
  end

  def only_default_value_stream_is_allowed!
    render_404 if params[:value_stream_id] != Analytics::CycleAnalytics::Stages::BaseService::DEFAULT_VALUE_STREAM_NAME
  end

  def permitted_stage?(stage)
    permissions[stage.name.to_sym] # name matches the permission key (only when default stages are used)
  end

  def permissions
    strong_memoize(:permissions) do
      Gitlab::CycleAnalytics::Permissions.new(user: current_user, project: parent).get
    end
  end

  def authorize_stage!
    render_403 unless permitted_stage?(stage)
  end
end
