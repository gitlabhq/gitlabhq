# frozen_string_literal: true

class RemoveAuditEventSyncWorkerJobs < Gitlab::Database::Migration[2.2]
  milestone '17.8'

  disable_ddl_transaction!

  DEPRECATED_JOB_CLASSES = %w[
    ::ClickHouse::AuditEventsSyncWorker
    ::ClickHouse::AuditEventPartitionSyncWorker
  ].freeze

  def up
    # Removes scheduled instances from Sidekiq queues
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes any instances of deprecated workers and cannot be undone.
  end
end
