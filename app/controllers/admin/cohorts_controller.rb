# frozen_string_literal: true

class Admin::CohortsController < Admin::ApplicationController
  include Analytics::UniqueVisitsHelper

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
    if request.format.html? && request.headers['DNT'] != '1'
      track_visit('i_analytics_cohorts')
    end
  end
end
