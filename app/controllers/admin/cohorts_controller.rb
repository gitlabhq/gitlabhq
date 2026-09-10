# frozen_string_literal: true

class Admin::CohortsController < Admin::ApplicationController
  include ProductAnalyticsTracking
  include Admin::CohortsActions

  track_event :index,
    name: 'i_analytics_cohorts',
    action: 'perform_analytics_usage_action',
    label: 'redis_hll_counters.analytics.analytics_total_unique_counts_monthly',
    destinations: %i[redis_hll snowplow]

  def index
    @cohorts = load_cohorts
  end

  private

  def tracking_namespace_source
    nil
  end

  def tracking_project_source
    nil
  end
end
