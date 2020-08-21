# frozen_string_literal: true

class Admin::DevOpsScoreController < Admin::ApplicationController
  include Analytics::UniqueVisitsHelper

  track_unique_visits :show, target_id: 'i_analytics_dev_ops_score'

  # rubocop: disable CodeReuse/ActiveRecord
  def show
    @metric = DevOpsScore::Metric.order(:created_at).last&.present
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
