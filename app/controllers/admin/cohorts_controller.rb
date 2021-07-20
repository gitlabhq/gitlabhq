# frozen_string_literal: true

class Admin::CohortsController < Admin::ApplicationController
  include RedisTracking

  feature_category :devops_reports

  def index
    @cohorts = load_cohorts
    track_cohorts_visit
  end

  private

  def load_cohorts
    cohorts_results = Rails.cache.fetch('cohorts', expires_in: 1.day) do
      CohortsService.new.execute
    end

    CohortsSerializer.new.represent(cohorts_results)
  end

  def track_cohorts_visit
    track_unique_redis_hll_event('i_analytics_cohorts') if trackable_html_request?
  end
end
