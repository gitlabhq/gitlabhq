# frozen_string_literal: true

class InstanceStatistics::DevOpsScoreController < InstanceStatistics::ApplicationController
  include Analytics::UniqueVisitsHelper

  track_unique_visits :index, target_id: 'i_analytics_dev_ops_score'

  # rubocop: disable CodeReuse/ActiveRecord
  def index
    @metric = DevOpsScore::Metric.order(:created_at).last&.present
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
