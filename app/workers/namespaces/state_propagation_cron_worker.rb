# frozen_string_literal: true

module Namespaces
  # Reconciliation worker for namespace state propagation.
  #
  # Resets `processing` records whose heartbeat (`started_at`) is older than
  # STUCK_THRESHOLD back to `pending`, then re-enqueues all `pending` records in
  # case their original job was lost.
  #
  # See https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/group_and_project_operations_and_state_management/decisions/003_state_propagation_model/
  class StatePropagationCronWorker
    include ApplicationWorker
    include CronjobQueue

    STUCK_THRESHOLD = 30.minutes
    BATCH_SIZE = 1_000

    data_consistency :sticky
    urgency :low
    defer_on_database_health_signal :gitlab_main, [:namespace_state_propagations], 1.minute
    feature_category :groups_and_projects
    idempotent!

    def perform
      log_extra_metadata_on_done(:reset_count, reset_stuck_processing_records)
      log_extra_metadata_on_done(:reenqueued_count, reenqueue_pending_records)
    end

    private

    def reset_stuck_processing_records
      reset_count = 0

      Namespaces::StatePropagation
        .stuck_processing(STUCK_THRESHOLD.ago)
        .each_batch(of: BATCH_SIZE) do |batch|
          reset_count += batch.update_all(status: Namespaces::StatePropagation.statuses[:pending], started_at: nil)
        end

      reset_count
    end

    def reenqueue_pending_records
      reenqueued_count = 0

      Namespaces::StatePropagation
        .pending
        .each_batch(of: BATCH_SIZE) do |batch|
          records = batch.with_namespace_route.to_a

          Namespaces::StatePropagationWorker.bulk_perform_async_with_contexts(
            records,
            arguments_proc: ->(record) { [record.namespace_id, record.target_state] },
            context_proc: ->(record) { { namespace: record.namespace } }
          )

          reenqueued_count += records.size
        end

      reenqueued_count
    end
  end
end
