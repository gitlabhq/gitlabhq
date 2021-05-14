# frozen_string_literal: true

class Projects::Analytics::CycleAnalytics::ValueStreamsController < Projects::ApplicationController
  respond_to :json

  feature_category :planning_analytics

  before_action :authorize_read_cycle_analytics!

  def index
    # FOSS users can only see the default value stream
    value_streams = [Analytics::CycleAnalytics::ProjectValueStream.build_default_value_stream(@project)]

    render json: Analytics::CycleAnalytics::ValueStreamSerializer.new.represent(value_streams)
  end
end
