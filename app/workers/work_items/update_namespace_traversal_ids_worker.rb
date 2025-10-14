# frozen_string_literal: true

module WorkItems
  class UpdateNamespaceTraversalIdsWorker
    include ApplicationWorker
    include Gitlab::ExclusiveLeaseHelpers

    feature_category :portfolio_management

    data_consistency :sticky
    idempotent!
    deduplicate :until_executing, including_scheduled: true

    concurrency_limit -> { 200 }

    RETRY_IN_IF_LOCKED = 20.seconds

    def perform(namespace_id)
      namespace = Namespace.find_by_id(namespace_id)
      return unless namespace

      UpdateNamespaceTraversalIdsService.execute(namespace)
    rescue Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError
      logger.info(
        class: self.class.name,
        message: "Couldn't obtain the lock. Rescheduling the job.",
        namespace_id: namespace_id)

      self.class.perform_in(RETRY_IN_IF_LOCKED, namespace_id)
    end
  end
end
