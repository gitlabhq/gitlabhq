# frozen_string_literal: true

class RemoveAdjustIndicesReservedStorageBytesEventWorker < Gitlab::Database::Migration[2.2]
  milestone '18.0'
  disable_ddl_transaction!
  DEPRECATED_JOB_CLASSES = %w[Search::Zoekt::AdjustIndicesReservedStorageBytesEventWorker]

  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down; end
end
