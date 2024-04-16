# frozen_string_literal: true

module ContainerRegistry
  module Migration
    class EnqueuerWorker
      include ApplicationWorker

      DEFAULT_LEASE_TIMEOUT = 30.minutes.to_i.freeze

      data_consistency :always
      feature_category :container_registry
      urgency :low
      deduplicate :until_executing, ttl: DEFAULT_LEASE_TIMEOUT
      idempotent!

      # No-op; in the process of removing this worker.
      # Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/409873
      def perform; end
    end
  end
end
