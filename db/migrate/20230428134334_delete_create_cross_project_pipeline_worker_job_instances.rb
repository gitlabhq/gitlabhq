# frozen_string_literal: true

class DeleteCreateCrossProjectPipelineWorkerJobInstances < Gitlab::Database::Migration[2.1]
  DEPRECATED_JOB_CLASSES = %w[
    CreateCrossProjectPipelineWorker
  ]

  disable_ddl_transaction!
  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes any instances of deprecated workers and cannot be undone.
  end
end
