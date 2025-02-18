# frozen_string_literal: true

class RemoveIndexOverWatermarkEventWorkerJobInstances < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  DEPRECATED_JOB_CLASSES = %w[Search::Zoekt::IndexOverWatermarkEventWorker]

  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes instances of a deprecated worker and cannot be undone.
  end
end
