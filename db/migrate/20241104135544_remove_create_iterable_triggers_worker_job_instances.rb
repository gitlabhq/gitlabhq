# frozen_string_literal: true

class RemoveCreateIterableTriggersWorkerJobInstances < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  DEPRECATED_JOB_CLASSES = %w[Onboarding::CreateIterableTriggersWorker]
  # Always use `disable_ddl_transaction!` while using the `sidekiq_remove_jobs` method,
  # as we had multiple production incidents due to `idle-in-transaction` timeout.
  disable_ddl_transaction!

  def up
    # Removes scheduled instances from Sidekiq queues
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes any instances of deprecated workers and cannot be undone.
  end
end
