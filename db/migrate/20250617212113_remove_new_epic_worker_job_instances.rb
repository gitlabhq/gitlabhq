# frozen_string_literal: true

class RemoveNewEpicWorkerJobInstances < Gitlab::Database::Migration[2.3]
  DEPRECATED_JOB_CLASS = %w[
    NewEpicWorker
  ]

  disable_ddl_transaction!
  milestone '18.2'

  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASS)
  end

  def down; end
end
