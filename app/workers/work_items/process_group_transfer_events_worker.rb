# frozen_string_literal: true

module WorkItems
  class ProcessGroupTransferEventsWorker
    include Gitlab::EventStore::Subscriber

    data_consistency :sticky

    idempotent!
    feature_category :portfolio_management
    deduplicate :until_executing, including_scheduled: true

    concurrency_limit -> { 200 }

    BATCH_SIZE = 100

    def self.handles_event?(event)
      group = Group.find_by_id(event.data[:group_id])
      return false unless group

      Feature.enabled?(:update_work_item_traversal_ids_on_transfer, group)
    end

    def handle_event(event)
      group = Group.find_by_id(event.data[:group_id])
      return unless group

      iterator = Gitlab::Database::NamespaceEachBatch
                   .new(namespace_class: Namespace, cursor: { current_id: group.id, depth: [group.id] })

      iterator.each_batch(of: BATCH_SIZE) do |namespace_ids|
        break unless namespace_ids.present?

        WorkItems::UpdateNamespaceTraversalIdsWorker.bulk_perform_async_with_contexts(
          namespace_ids,
          arguments_proc: ->(namespace_id) { namespace_id },
          context_proc: ->(_) { {} } # No namespace context because loading the namespace is wasteful
        )
      end
    end
  end
end
