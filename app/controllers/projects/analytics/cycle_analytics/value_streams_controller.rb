# frozen_string_literal: true

class Projects::Analytics::CycleAnalytics::ValueStreamsController < Projects::ApplicationController
  extend ::Gitlab::Utils::Override
  include ::Analytics::CycleAnalytics::ValueStreamActions

  respond_to :json

  feature_category :team_planning
  urgency :low

  private

  def namespace
    project.project_namespace
  end
end

Projects::Analytics::CycleAnalytics::ValueStreamsController.prepend_mod
