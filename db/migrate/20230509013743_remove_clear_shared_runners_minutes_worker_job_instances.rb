# frozen_string_literal: true

class RemoveClearSharedRunnersMinutesWorkerJobInstances < Gitlab::Database::Migration[2.1]
  DEPRECATED_JOB_CLASSES = %w[
    ClearSharedRunnersMinutesWorker
    Ci::BatchResetMinutesWorker
  ]
  disable_ddl_transaction!
  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down; end
end
