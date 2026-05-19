# frozen_string_literal: true

class RemoveExpireBuildArtifactsWorkerJobInstances < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  # Always use `disable_ddl_transaction!` while using the `sidekiq_remove_jobs` method,
  # as we had multiple production incidents due to `idle-in-transaction` timeout.
  disable_ddl_transaction!

  DEPRECATED_JOB_CLASSES = %w[
    ExpireBuildArtifactsWorker
  ]

  def up
    Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
      job_to_remove = Sidekiq::Cron::Job.find('expire_build_artifacts_worker')
      job_to_remove.destroy if job_to_remove
    end

    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes any instances of deprecated workers and cannot be undone.
  end
end
