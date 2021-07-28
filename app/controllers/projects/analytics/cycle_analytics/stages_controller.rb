# frozen_string_literal: true

class Projects::Analytics::CycleAnalytics::StagesController < Projects::ApplicationController
  include ::Analytics::CycleAnalytics::StageActions
  extend ::Gitlab::Utils::Override

  respond_to :json

  feature_category :planning_analytics

  before_action :authorize_read_cycle_analytics!
  before_action :only_default_value_stream_is_allowed!

  private

  override :parent
  def parent
    @project
  end

  override :value_stream_class
  def value_stream_class
    Analytics::CycleAnalytics::ProjectValueStream
  end

  def only_default_value_stream_is_allowed!
    render_404 if params[:value_stream_id] != Analytics::CycleAnalytics::Stages::BaseService::DEFAULT_VALUE_STREAM_NAME
  end
end
