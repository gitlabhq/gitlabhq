# frozen_string_literal: true

module IncidentManagement
  class ProcessPrometheusAlertWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    sidekiq_options retry: 3

    queue_namespace :incident_management
    feature_category :incident_management
    worker_resource_boundary :cpu

    def perform(project_id, alert_hash)
      # no-op
      #
      # This worker is not scheduled anymore since
      # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/35943
      # and will be removed completely via
      # https://gitlab.com/gitlab-org/gitlab/-/issues/227146
      # in 14.0.
    end
  end
end
