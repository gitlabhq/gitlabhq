# frozen_string_literal: true

class Projects::Analytics::CycleAnalytics::StagesController < Projects::ApplicationController
  include ::Analytics::CycleAnalytics::StageActions
  include Gitlab::Utils::StrongMemoize

  respond_to :json

  feature_category :team_planning

  before_action :authorize_read_cycle_analytics!
  before_action :only_default_value_stream_is_allowed!

  urgency :low

  private

  override :namespace
  def namespace
    @project.project_namespace
  end

  override :cycle_analytics_configuration
  def cycle_analytics_configuration(stages)
    super(stages.select { |stage| permitted_stage?(stage) })
  end

  def only_default_value_stream_is_allowed!
    return if requests_default_value_stream?

    render_403
  end

  def permitted_stage?(stage)
    permissions[stage.name.to_sym] # name matches the permission key (only when default stages are used)
  end

  def permissions
    strong_memoize(:permissions) do
      Gitlab::CycleAnalytics::Permissions.new(user: current_user, project: @project).get
    end
  end

  def authorize_stage
    render_403 unless permitted_stage?(stage)
  end

  def requests_default_value_stream?
    default_name = Analytics::CycleAnalytics::Stages::BaseService::DEFAULT_VALUE_STREAM_NAME

    params[:value_stream_id] == default_name
  end
end

mod = 'Projects::Analytics::CycleAnalytics::StagesController'
Projects::Analytics::CycleAnalytics::StagesController.prepend_mod_with(mod) # rubocop: disable Cop/InjectEnterpriseEditionModule
