# frozen_string_literal: true

module ContainerRegistry
  # Deprecated. Scheduled for removal in 19.2 after the 19.1 sidekiq_remove_jobs
  # migration drains any lingering jobs from Redis. See
  # https://gitlab.com/gitlab-org/gitlab/-/issues/580354 and
  # https://docs.gitlab.com/ee/development/sidekiq/compatibility_across_updates.html#removing-worker-classes
  class RecordDataRepairDetailWorker
    include ApplicationWorker

    data_consistency :always
    queue_namespace :container_repository
    feature_category :container_registry
    urgency :low
    idempotent!

    sidekiq_options retry: 0

    def perform(*); end
  end
end
