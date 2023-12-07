# frozen_string_literal: true

class RemoveGeoPrimaryDeprecatedWorkersJobInstances < Gitlab::Database::Migration[2.2]
  DEPRECATED_JOB_CLASSES = %w[
    Geo::RepositoryVerification::Primary::BatchWorker
    Geo::RepositoryVerification::Primary::ShardWorker
    Geo::RepositoryVerification::Primary::SingleWorker
    Geo::RepositoryVerification::Secondary::SingleWorker
    Geo::Scheduler::Primary::PerShardSchedulerWorker
    Geo::Scheduler::Primary::SchedulerWorker
  ]

  disable_ddl_transaction!

  milestone '16.7'

  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes any instances of deprecated workers and cannot be undone.
  end
end
