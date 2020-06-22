# frozen_string_literal: true

class InstanceStatistics::CohortsController < InstanceStatistics::ApplicationController
  include Analytics::UniqueVisitsHelper

  before_action :authenticate_usage_ping_enabled_or_admin!

  track_unique_visits :index, target_id: 'i_analytics_cohorts'

  def index
    if Gitlab::CurrentSettings.usage_ping_enabled
      cohorts_results = Rails.cache.fetch('cohorts', expires_in: 1.day) do
        CohortsService.new.execute
      end

      @cohorts = CohortsSerializer.new.represent(cohorts_results)
    end
  end

  def authenticate_usage_ping_enabled_or_admin!
    render_404 unless Gitlab::CurrentSettings.usage_ping_enabled || current_user.admin?
  end
end
