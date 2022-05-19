# frozen_string_literal: true

module Prometheus
  class CreateDefaultAlertsWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    feature_category :incident_management
    urgency :high
    idempotent!

    def perform(project_id)
      # No-op Will be removed in https://gitlab.com/gitlab-org/gitlab/-/issues/360756
    end
  end
end
