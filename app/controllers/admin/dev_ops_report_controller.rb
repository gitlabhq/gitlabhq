# frozen_string_literal: true

class Admin::DevOpsReportController < Admin::ApplicationController
  include RedisTracking

  helper_method :show_adoption?

  track_redis_hll_event :show, name: 'i_analytics_dev_ops_score', if: -> { should_track_devops_score? }

  feature_category :devops_reports

  # rubocop: disable CodeReuse/ActiveRecord
  def show
    @metric = DevOpsReport::Metric.order(:created_at).last&.present
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def show_adoption?
    false
  end

  def should_track_devops_score?
    true
  end
end

Admin::DevOpsReportController.prepend_mod_with('Admin::DevOpsReportController')
