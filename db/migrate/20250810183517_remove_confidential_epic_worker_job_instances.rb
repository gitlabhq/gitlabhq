# frozen_string_literal: true

class RemoveConfidentialEpicWorkerJobInstances < Gitlab::Database::Migration[2.3]
  milestone '18.4'
  DEPRECATED_JOB_CLASS = %w[
    ConfidentialEpicWorker
  ]

  disable_ddl_transaction!

  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASS)
  end

  def down; end
end
