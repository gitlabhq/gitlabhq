# frozen_string_literal: true

module Namespaces
  class CancelStuckTransfersService
    # A namespace in transfer_in_progress with no updates for this long is considered stuck.
    # 4 hours allows for Sidekiq retries (3 retries with exponential backoff) plus lease expiry (30 min).
    STUCK_IN_PROGRESS_TIMEOUT = 4.hours

    # A namespace in transfer_scheduled with no updates for this long means the worker never picked it up.
    # 1 hour is generous given normal Sidekiq queue latency is seconds.
    STUCK_SCHEDULED_TIMEOUT = 1.hour

    BATCH_SIZE = 100

    def execute
      total_cancelled = 0

      total_cancelled += cancel_stuck_in_progress
      total_cancelled += cancel_stuck_scheduled

      Gitlab::AppLogger.info(
        message: 'CancelStuckTransfersService completed',
        total_cancelled: total_cancelled
      )

      total_cancelled
    end

    private

    def cancel_stuck_in_progress
      cancel_stuck_namespaces(
        Namespace.stuck_in_transfer_in_progress(STUCK_IN_PROGRESS_TIMEOUT),
        'transfer_in_progress'
      )
    end

    def cancel_stuck_scheduled
      cancel_stuck_namespaces(
        Namespace.stuck_in_transfer_scheduled(STUCK_SCHEDULED_TIMEOUT),
        'transfer_scheduled'
      )
    end

    def cancel_stuck_namespaces(scope, state_label)
      cancelled = 0

      scope.each_batch(of: BATCH_SIZE) do |batch|
        batch.each do |namespace|
          next if active_worker_lease?(namespace)

          cancel_transfer(namespace, state_label)
          cancelled += 1
        rescue StandardError => e
          Gitlab::AppLogger.error(
            message: 'CancelStuckTransfersService failed to cancel stuck transfer',
            namespace_id: namespace.id,
            namespace_type: namespace.type,
            state: state_label,
            error: e.message
          )
        end
      end

      cancelled
    end

    def active_worker_lease?(namespace)
      lease_key = worker_lease_key(namespace)
      return false unless lease_key

      Gitlab::ExclusiveLease.get_uuid(lease_key).present?
    end

    def worker_lease_key(namespace)
      case namespace
      when Group
        Namespaces::Groups::TransferWorker.lease_key(namespace.id)
      when Namespaces::ProjectNamespace
        ::Projects::TransferWorker.lease_key(namespace.project.id)
      else
        Gitlab::AppLogger.warn(
          message: 'CancelStuckTransfersService: unhandled namespace type, skipping lease check',
          namespace_id: namespace.id,
          namespace_type: namespace.type
        )
        nil
      end
    end

    def cancel_transfer(namespace, state_label)
      stuck_duration = Time.current - namespace.updated_at

      Gitlab::AppLogger.warn(
        message: 'Cancelling stuck transfer - no active worker lease found',
        namespace_id: namespace.id,
        namespace_type: namespace.type,
        state: state_label,
        stuck_duration_seconds: stuck_duration.to_i,
        transfer_scheduled_at: namespace.state_metadata&.dig('transfer_scheduled_at'),
        transfer_initiated_at: namespace.state_metadata&.dig('transfer_initiated_at')
      )

      namespace.cancel_transfer!
    end
  end
end
