# frozen_string_literal: true

module WorkItems
  # Periodically heals divergence between a namespace's traversal_ids and the
  # namespace_traversal_ids denormalized onto the issues table.
  # This is necessary to handle cases where we missed to spawn the UpdateNamespaceTraversalIdsWorker
  # either due to unkown bugs in our system, or when there was a problem with the sidekiq job queue.
  class TraversalIdsHealingCronWorker
    include ApplicationWorker
    include LoopWithRuntimeLimit
    include CronjobQueue

    data_consistency :sticky
    deduplicate :until_executing, including_scheduled: true
    feature_category :portfolio_management
    idempotent!

    MAX_RUNTIME = 200.seconds
    BATCH_SIZE = ApplicationRecord::MAX_PLUCK
    RESCHEDULE_DELAY = 5.minutes
    CURSOR_KEY = 'work_items:traversal_ids_healing:last_namespace_id'
    CURSOR_TTL = 1.day

    def perform
      return unless Feature.enabled?(:work_items_traversal_ids_healing_service) # rubocop:disable Gitlab/FeatureFlagWithoutActor -- Global job, no actor needed

      cursor = load_cursor
      heals_enqueued = 0
      namespaces_scanned = 0

      result = loop_with_runtime_limit(MAX_RUNTIME) do |_runtime_limiter|
        namespace_ids = next_namespace_ids(cursor)
        break :complete if namespace_ids.empty?

        divergent_ids = DivergentTraversalIds.among(namespace_ids)
        enqueue_heals(divergent_ids)

        cursor = namespace_ids.last
        save_cursor(cursor)

        heals_enqueued += divergent_ids.size
        namespaces_scanned += namespace_ids.size
      end

      result == :complete ? delete_cursor : self.class.perform_in(RESCHEDULE_DELAY)

      log_extra_metadata_on_done(
        :result,
        { heals_enqueued: heals_enqueued, namespaces_scanned: namespaces_scanned }
      )
    end

    private

    def next_namespace_ids(cursor)
      Namespace.ordered_ids_after(cursor, limit: BATCH_SIZE)
    end

    def enqueue_heals(namespace_ids)
      return if namespace_ids.empty?

      Gitlab::AppLogger.info(
        message: 'Enqueuing traversal_id heals for divergent namespaces',
        count: namespace_ids.size,
        namespace_ids: namespace_ids
      )
      WorkItems::UpdateNamespaceTraversalIdsWorker.bulk_perform_async_with_contexts(
        namespace_ids,
        arguments_proc: ->(namespace_id) { namespace_id },
        context_proc: ->(_namespace_id) { {} }
      )
    end

    def load_cursor
      Gitlab::Redis::SharedState.with { |redis| redis.get(CURSOR_KEY).to_i }
    end

    def save_cursor(cursor)
      Gitlab::Redis::SharedState.with { |redis| redis.set(CURSOR_KEY, cursor, ex: CURSOR_TTL) }
    end

    def delete_cursor
      Gitlab::Redis::SharedState.with { |redis| redis.del(CURSOR_KEY) }
    end
  end
end
