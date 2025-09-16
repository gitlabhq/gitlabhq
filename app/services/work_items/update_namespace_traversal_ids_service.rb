# frozen_string_literal: true

module WorkItems
  class UpdateNamespaceTraversalIdsService
    include Gitlab::ExclusiveLeaseHelpers

    BATCH_SIZE = 100
    LEASE_TTL = 5.minutes
    LEASE_TRY_AFTER = 3.seconds

    def self.execute(namespace)
      new(namespace).execute
    end

    def initialize(namespace)
      @namespace = namespace
    end

    def execute
      in_lock(lease_key, ttl: LEASE_TTL, sleep_sec: LEASE_TRY_AFTER) { update_work_items }
    end

    private

    attr_reader :namespace

    def update_work_items
      # Important: We use database traversal_ids to mitigate race conditions when namespace.traversal_ids
      # becomes stale due to concurrent namespace transfers. This means that the traversal_ids could change while we run
      # the batched updated.
      # We can't eliminate the race condition, but any record with outdated traversal_ids will be corrected by
      # the subsequent worker.
      namespace.work_items.each_batch(column: :iid, of: BATCH_SIZE) do |batch|
        # In the case that we see an issue with transferring large namespaces, we want to be able to stop the updates.
        break unless Feature.enabled?(:update_work_item_traversal_ids_on_transfer, namespace)

        batch.update_all(
          ["namespace_traversal_ids = (SELECT traversal_ids FROM namespaces WHERE id = ?)", namespace.id]
        )
      end
    end

    def lease_key
      "work_items:#{namespace.id}:update_namespace_traversal_ids"
    end
  end
end
