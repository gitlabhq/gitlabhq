# frozen_string_literal: true

class Admin::DevOpsReportController < Admin::ApplicationController
  include Analytics::UniqueVisitsHelper

  track_unique_visits :show, target_id: 'i_analytics_dev_ops_score'

  feature_category :devops_reports

  # rubocop: disable CodeReuse/ActiveRecord
  def show
    @metric = DevOpsReport::Metric.order(:created_at).last&.present
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
