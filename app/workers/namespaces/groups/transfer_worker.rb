# frozen_string_literal: true

# rubocop:disable Scalability/IdempotentWorker -- transfer service itself is not idempotent
module Namespaces
  module Groups
    class TransferWorker
      include ApplicationWorker
      include Namespaces::TransferWorkerHelper

      data_consistency :sticky
      sidekiq_options retry: 3

      feature_category :groups_and_projects
      urgency :low

      defer_on_database_health_signal :gitlab_main, [:groups], 1.minute

      LEASE_TIMEOUT = 30.minutes.to_i

      def self.lease_key(group_id)
        "namespaces_groups_transfer_worker:#{group_id}"
      end

      def perform(group_id, new_parent_group_id, user_id)
        group = Group.find_by_id(group_id)
        return unless group

        user = User.find_by_id(user_id)
        return unless user

        new_parent_group = Group.find_by_id(new_parent_group_id) if new_parent_group_id

        lease_key = self.class.lease_key(group_id)
        exclusive_lease = Gitlab::ExclusiveLease.new(lease_key, uuid: jid, timeout: LEASE_TIMEOUT)
        lease = exclusive_lease.try_obtain

        if lease
          execute_transfer(group, new_parent_group, user, exclusive_lease)
        else
          handle_lease_conflict(group, lease_key, exclusive_lease)
        end
      end

      private

      def execute_transfer(group, new_parent_group, user, exclusive_lease)
        start_time = Gitlab::Metrics::System.monotonic_time
        transfer_started = false
        transfer_succeeded = false
        cancel_stale_transfer_state(group, group_id: group.id)

        group.schedule_transfer!(transition_user: user) unless group.transfer_scheduled?
        group.start_transfer!(transition_user: user)
        transfer_started = true

        transfer_successful = ::Groups::TransferService.new(group, user).execute(new_parent_group)

        if transfer_successful
          transfer_succeeded = true
          group.complete_transfer!
          resolve_transfer_failure_todo(group, user, worker_name: self.class.name, group_id: group.id)

        else
          create_transfer_failure_todo(group, user, worker_name: self.class.name, group_id: group.id)
          group.cancel_transfer!
        end
      rescue StandardError => e

        if transfer_started && !transfer_succeeded
          create_transfer_failure_todo(group, user, worker_name: self.class.name, group_id: group.id)
        end

        begin
          cancel_transfer_if_in_progress(group)
        rescue StandardError => cancel_error
          Gitlab::AppLogger.error(
            build_transfer_log_payload(
              message: 'Namespaces::Groups::TransferWorker failed to cancel transfer state',
              namespace: group,
              error: cancel_error,
              duration_s: elapsed_seconds(start_time),
              group_id: group.id
            )
          )
        end

        Gitlab::AppLogger.error(
          build_transfer_log_payload(
            message: 'Namespaces::Groups::TransferWorker failed',
            namespace: group,
            error: e,
            duration_s: elapsed_seconds(start_time),
            group_id: group.id,
            new_parent_group_id: new_parent_group&.id
          )
        )

        ::Gitlab::Metrics::Transfers.count_transfer(namespace_type: 'group', result: 'failure')

        raise
      ensure
        exclusive_lease.cancel
      end

      def handle_lease_conflict(group, lease_key, exclusive_lease)
        uuid = Gitlab::ExclusiveLease.get_uuid(lease_key)

        # Handle Sidekiq interrupt: if the worker was killed and rescheduled with the same jid,
        # reset the stale state and release the lock so a subsequent retry can proceed.
        return unless uuid == jid

        cancel_transfer_if_in_progress(group)
        exclusive_lease.cancel
      end

      def cancel_transfer_if_in_progress(group)
        group.cancel_transfer! if group.transfer_in_progress?
      end
    end
  end
end
# rubocop:enable Scalability/IdempotentWorker
