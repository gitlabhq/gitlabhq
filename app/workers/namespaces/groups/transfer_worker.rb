# frozen_string_literal: true

# rubocop:disable Scalability/IdempotentWorker -- transfer service itself is not idempotent
module Namespaces
  module Groups
    class TransferWorker
      include ApplicationWorker

      data_consistency :sticky
      sidekiq_options retry: 3

      feature_category :groups_and_projects
      urgency :low

      defer_on_database_health_signal :gitlab_main, [:groups], 1.minute

      LEASE_TIMEOUT = 30.minutes.to_i

      def perform(group_id, new_parent_group_id, user_id)
        group = Group.find_by_id(group_id)
        return unless group

        user = User.find_by_id(user_id)
        return unless user

        new_parent_group = Group.find_by_id(new_parent_group_id) if new_parent_group_id

        lease_key = ['namespaces_groups_transfer_worker', group_id].join(':')
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
        group.start_transfer!(transition_user: user)

        transfer_successful = ::Groups::TransferService.new(group, user).execute(new_parent_group)

        if transfer_successful
          group.complete_transfer!
        else
          group.cancel_transfer!
        end
      rescue StandardError => e
        begin
          cancel_transfer_if_in_progress(group)
        rescue StandardError => cancel_error
          Gitlab::AppLogger.error(
            message: 'Namespaces::Groups::TransferWorker failed to cancel transfer state',
            group_id: group.id,
            error: cancel_error.message
          )
        end

        Gitlab::AppLogger.error(
          message: 'Namespaces::Groups::TransferWorker failed',
          group_id: group.id,
          new_parent_group_id: new_parent_group&.id,
          error: e.message
        )

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
