# frozen_string_literal: true

class RemoveElasticIndexingControlWorkerJobInstances < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.10'

  DEPRECATED_JOB_CLASSES = %w[ElasticIndexingControlWorker]

  def up
    Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
      job_to_remove = Sidekiq::Cron::Job.find('elastic_indexing_control_worker')
      job_to_remove.destroy if job_to_remove
    end

    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes instances of a deprecated worker and cannot be undone.
  end
end
