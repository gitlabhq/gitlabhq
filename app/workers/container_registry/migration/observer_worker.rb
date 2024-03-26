# frozen_string_literal: true

module ContainerRegistry
  module Migration
    class ObserverWorker
      include ApplicationWorker

      data_consistency :sticky
      feature_category :container_registry
      urgency :low
      deduplicate :until_executed, including_scheduled: true
      idempotent!

      # No-op; in the process of removing this worker.
      # Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/409873
      def perform; end
    end
  end
end
