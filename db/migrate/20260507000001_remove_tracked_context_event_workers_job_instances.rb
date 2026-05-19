# frozen_string_literal: true

class RemoveTrackedContextEventWorkersJobInstances < Gitlab::Database::Migration[2.3]
  milestone '19.0'
  disable_ddl_transaction!

  DEPRECATED_JOB_CLASSES = %w[
    Security::CreateDefaultTrackedContextWorker
    Security::ProjectTrackedContexts::UpdateDefaultContextWorker
  ]

  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes any instances of deprecated workers and cannot be undone.
  end
end
