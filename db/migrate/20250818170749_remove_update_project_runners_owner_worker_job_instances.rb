# frozen_string_literal: true

class RemoveUpdateProjectRunnersOwnerWorkerJobInstances < Gitlab::Database::Migration[2.3]
  milestone '18.4'
  disable_ddl_transaction!

  DEPRECATED_JOB_CLASSES = %w[Ci::Runners::UpdateProjectRunnersOwnerWorker]

  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes any instances of deprecated workers and cannot be undone.
  end
end
