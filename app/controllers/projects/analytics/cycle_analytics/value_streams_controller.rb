# frozen_string_literal: true

class Projects::Analytics::CycleAnalytics::ValueStreamsController < Projects::ApplicationController
  include ::Analytics::CycleAnalytics::ValueStreamActions

  respond_to :json

  feature_category :team_planning
  urgency :low

  private

  def namespace
    project.project_namespace
  end
end
