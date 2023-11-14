# frozen_string_literal: true

class RemoveTasksToBeDoneWorker < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  DEPRECATED_JOB_CLASSES = %w[TasksToBeDone::CreateWorker]

  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes any instances of deprecated workers and cannot be undone.
  end
end
