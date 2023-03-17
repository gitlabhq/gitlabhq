# frozen_string_literal: true

class Admin::CohortsController < Admin::ApplicationController
  include ProductAnalyticsTracking

  feature_category :devops_reports

  urgency :low

  track_event :index,
    name: 'i_analytics_cohorts',
    action: 'perform_analytics_usage_action',
    label: 'redis_hll_counters.analytics.analytics_total_unique_counts_monthly',
    destinations: %i[redis_hll snowplow]

  def index
    @cohorts = load_cohorts
  end

  private

  def load_cohorts
    cohorts_results = Rails.cache.fetch('cohorts', expires_in: 1.day) do
      CohortsService.new.execute
    end

    CohortsSerializer.new.represent(cohorts_results)
  end

  def tracking_namespace_source
    nil
  end

  def tracking_project_source
    nil
  end
end
