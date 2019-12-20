# frozen_string_literal: true

class InstanceStatistics::DevOpsScoreController < InstanceStatistics::ApplicationController
  # rubocop: disable CodeReuse/ActiveRecord
  def index
    @metric = DevOpsScore::Metric.order(:created_at).last&.present
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
