# frozen_string_literal: true

module WorkItems
  # Keeps work_item_positions.relative_positioning_namespace_id (the work item's
  # positioning root, Namespace#work_item_positioning_root) in sync after the
  # hierarchy changes - e.g. a group/project transfer, which moves the root
  # without touching the issues rows the sync trigger fires on.
  #
  # Enqueued via the same path as UpdateNamespaceTraversalIdsService (transfer
  # events for the moved subtree + the healing cron), so it inherits the same
  # coverage.
  class UpdatePositioningNamespaceIdService
    BATCH_SIZE = 100

    def self.execute(namespace)
      new(namespace).execute
    end

    def initialize(namespace)
      @namespace = namespace
    end

    def execute
      namespace.work_items.each_batch(column: :iid, of: BATCH_SIZE) do |batch|
        WorkItems::Position.refresh_relative_positioning_namespace_id(batch)
      end
    end

    private

    attr_reader :namespace
  end
end
