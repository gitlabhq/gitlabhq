# frozen_string_literal: true

class Projects::Analytics::CycleAnalytics::ValueStreamsController < Projects::ApplicationController
  extend ::Gitlab::Utils::Override
  include ::Analytics::CycleAnalytics::ValueStreamActions

  respond_to :json

  feature_category :value_stream_management
  urgency :low

  private

  def namespace
    project.project_namespace
  end
end

Projects::Analytics::CycleAnalytics::ValueStreamsController.prepend_mod
