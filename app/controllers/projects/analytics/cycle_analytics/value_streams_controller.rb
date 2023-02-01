# frozen_string_literal: true

class Projects::Analytics::CycleAnalytics::ValueStreamsController < Projects::ApplicationController
  include ::Analytics::CycleAnalytics::ValueStreamActions

  respond_to :json

  feature_category :planning_analytics
  urgency :low

  private

  def namespace
    project.project_namespace
  end
end
