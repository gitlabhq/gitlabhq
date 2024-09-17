# frozen_string_literal: true

class Admin::UsageTrendsController < Admin::ApplicationController
  include ProductAnalyticsTracking

  track_event :index,
    name: 'i_analytics_instance_statistics',
    action: 'perform_analytics_usage_action',
    label: 'redis_hll_counters.analytics.analytics_total_unique_counts_monthly',
    destinations: %i[redis_hll snowplow]

  feature_category :devops_reports

  urgency :low

  def index; end

  def tracking_namespace_source
    @group
  end

  def tracking_project_source
    nil
  end
end
