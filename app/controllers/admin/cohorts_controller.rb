# frozen_string_literal: true

class Admin::CohortsController < Admin::ApplicationController
  include Analytics::UniqueVisitsHelper

  track_unique_visits :index, target_id: 'i_analytics_cohorts'

  feature_category :devops_reports

  def index
    if Gitlab::CurrentSettings.usage_ping_enabled
      cohorts_results = Rails.cache.fetch('cohorts', expires_in: 1.day) do
        CohortsService.new.execute
      end

      @cohorts = CohortsSerializer.new.represent(cohorts_results)
    end
  end
end
