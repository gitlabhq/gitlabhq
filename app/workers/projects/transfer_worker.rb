# frozen_string_literal: true

# rubocop:disable Scalability/IdempotentWorker -- transfer service itself is not idempotent
module Projects
  class TransferWorker
    include ApplicationWorker

    data_consistency :sticky
    sidekiq_options retry: 3

    feature_category :groups_and_projects
    urgency :low

    defer_on_database_health_signal :gitlab_main, [:projects], 1.minute

    LEASE_TIMEOUT = 30.minutes.to_i

    def perform(project_id, new_namespace_id, user_id)
      project = Project.find_by_id(project_id)
      return unless project

      user = User.find_by_id(user_id)
      return unless user

      new_namespace = Namespace.find_by_id(new_namespace_id)
      return unless new_namespace

      lease_key = ['projects_transfer_worker', project_id].join(':')
      exclusive_lease = Gitlab::ExclusiveLease.new(lease_key, uuid: jid, timeout: LEASE_TIMEOUT)
      lease = exclusive_lease.try_obtain

      if lease
        execute_transfer(project, new_namespace, user, exclusive_lease)
      else
        handle_lease_conflict(project, lease_key, exclusive_lease)
      end
    end

    private

    def execute_transfer(project, new_namespace, user, exclusive_lease)
      project_namespace = project.project_namespace

      project_namespace.start_transfer!(transition_user: user)

      result = ::Projects::TransferService.new(project, user).execute(new_namespace)

      if result
        project_namespace.complete_transfer!
      else
        project_namespace.cancel_transfer!
      end
    rescue StandardError => e
      begin
        cancel_transfer_if_in_progress(project_namespace)
      rescue StandardError => cancel_error
        Gitlab::AppLogger.error(
          message: 'Projects::TransferWorker failed to cancel transfer state',
          project_id: project.id,
          error: cancel_error.message
        )
      end

      Gitlab::AppLogger.error(
        message: 'Projects::TransferWorker failed',
        project_id: project.id,
        new_namespace_id: new_namespace.id,
        error: e.message
      )

      raise
    ensure
      exclusive_lease.cancel
    end

    def handle_lease_conflict(project, lease_key, exclusive_lease)
      uuid = Gitlab::ExclusiveLease.get_uuid(lease_key)

      # Handle Sidekiq interrupt: if the worker was killed and rescheduled with the same jid,
      # reset the stale state and release the lock so a subsequent retry can proceed.
      return unless uuid == jid

      cancel_transfer_if_in_progress(project.project_namespace)
      exclusive_lease.cancel
    end

    def cancel_transfer_if_in_progress(project_namespace)
      project_namespace.cancel_transfer! if project_namespace.transfer_in_progress?
    end
  end
end
# rubocop:enable Scalability/IdempotentWorker
