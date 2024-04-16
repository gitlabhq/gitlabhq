# frozen_string_literal: true

module ContainerRegistry
  module Migration
    class GuardWorker
      include ApplicationWorker

      data_consistency :always
      feature_category :container_registry
      urgency :low
      worker_resource_boundary :unknown
      deduplicate :until_executed, ttl: 5.minutes
      idempotent!

      # No-op; in the process of removing this worker.
      # Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/409873
      def perform; end
    end
  end
end
