# frozen_string_literal: true

module ObjectPool # rubocop:disable Gitlab/BoundedContexts -- Existing module shared with the other ObjectPool workers
  class DisconnectWorker
    include ApplicationWorker

    data_consistency :always # rubocop:disable SidekiqLoadBalancing/WorkerDataConsistency -- needs primary DB read for disk_path race condition guard

    include ObjectPoolQueue

    feature_category :source_code_management

    idempotent!

    sidekiq_retries_exhausted do |job, exception|
      project_id, pool_disk_path = job['args']

      Gitlab::ErrorTracking.track_exception(
        exception, project_id: project_id, pool_disk_path: pool_disk_path
      )
    end

    def perform(project_id, pool_disk_path)
      project = Project.find_by_id(project_id)
      return if project.nil?

      pool = project.pool_repository
      # Storage moves swap in a same-path pool on the new shard; a different path is a genuine re-link.
      # A redelivered job cannot distinguish the original membership from a later re-link to the same
      # pool; this risk is accepted, as in Repositories::LeavePoolRepositoryWorker.
      return if pool.nil? || pool.disk_path != pool_disk_path

      project.leave_pool_repository
    end
  end
end
