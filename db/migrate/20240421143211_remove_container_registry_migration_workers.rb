# frozen_string_literal: true

class RemoveContainerRegistryMigrationWorkers < Gitlab::Database::Migration[2.2]
  DEPRECATED_JOB_CLASSES = %w[
    ContainerRegistry::Migration::EnqueuerWorker
    ContainerRegistry::Migration::GuardWorker
    ContainerRegistry::Migration::ObserverWorker
  ]

  milestone '17.0'
  disable_ddl_transaction!

  def up
    # The job has been scheduled via sidekiq-cron, so we are removing
    # it from the scheduled worker using the keys removed from 1_settings.rb
    # in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147228
    cron_job_keys = %w[
      container_registry_migration_guard_worker
      container_registry_migration_observer_worker
      container_registry_migration_enqueuer_worker
    ]

    # TODO: make shard-aware. See https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/3430
    Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
      cron_job_keys.each do |job_key|
        job_to_remove = Sidekiq::Cron::Job.find(job_key)
        job_to_remove.destroy if job_to_remove
      end
    end

    # Removes scheduled instances from Sidekiq queues
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes any instances of deprecated workers and cannot be undone.
  end
end
