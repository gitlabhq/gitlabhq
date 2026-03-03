# frozen_string_literal: true

class RemoveStageUpdateWorkerJobs < Gitlab::Database::Migration[2.3]
  milestone '18.10'
  disable_ddl_transaction!

  DEPRECATED_JOB_CLASS = %w[
    StageUpdateWorker
  ]

  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASS)
  end

  def down; end
end
