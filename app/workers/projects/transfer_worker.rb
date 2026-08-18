# frozen_string_literal: true

# rubocop:disable Scalability/IdempotentWorker -- transfer service itself is not idempotent
module Projects
  class TransferWorker
    include ApplicationWorker
    include Namespaces::TransferWorkerHelper

    data_consistency :sticky
    sidekiq_options retry: 3

    feature_category :groups_and_projects
    urgency :low

    defer_on_database_health_signal :gitlab_main, [:projects], 1.minute

    LEASE_TIMEOUT = 30.minutes.to_i

    def self.lease_key(project_id)
      "projects_transfer_worker:#{project_id}"
    end

    def perform(project_id, new_namespace_id, user_id)
      project = Project.find_by_id(project_id)
      return unless project

      user = User.find_by_id(user_id)
      return unless user

      new_namespace = Namespace.find_by_id(new_namespace_id)
      return unless new_namespace

      lease_key = self.class.lease_key(project_id)
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
      start_time = Gitlab::Metrics::System.monotonic_time
      transfer_started = false
      transfer_succeeded = false

      cancel_stale_transfer_state(project_namespace, gl_project_id: project.id)

      project_namespace.schedule_transfer!(transition_user: user) unless project_namespace.transfer_scheduled?
      project_namespace.start_transfer!(transition_user: user)
      transfer_started = true

      result = ::Projects::TransferService.new(project, user).execute(new_namespace)

      if result
        transfer_succeeded = true
        project_namespace.complete_transfer!
        resolve_transfer_failure_todo(project, user, worker_name: self.class.name, gl_project_id: project.id)

      else
        create_transfer_failure_todo(project, user, worker_name: self.class.name, gl_project_id: project.id)
        project_namespace.cancel_transfer!
      end
    rescue StandardError => e
      if transfer_started && !transfer_succeeded
        create_transfer_failure_todo(project, user, worker_name: self.class.name, gl_project_id: project.id)
      end

      begin
        cancel_transfer_if_in_progress(project_namespace)
      rescue StandardError => cancel_error
        Gitlab::AppLogger.error(
          build_transfer_log_payload(
            message: 'Projects::TransferWorker failed to cancel transfer state',
            namespace: project_namespace,
            error: cancel_error,
            duration_s: elapsed_seconds(start_time),
            gl_project_id: project.id
          )
        )
      end

      Gitlab::AppLogger.error(
        build_transfer_log_payload(
          message: 'Projects::TransferWorker failed',
          namespace: project_namespace,
          error: e,
          duration_s: elapsed_seconds(start_time),
          gl_project_id: project.id,
          new_namespace_id: new_namespace.id
        )
      )

      ::Gitlab::Metrics::Transfers.count_transfer(namespace_type: 'project', result: 'failure')

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
