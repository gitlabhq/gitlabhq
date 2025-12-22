# frozen_string_literal: true

class RemoveVRegMarkEntriesForDestructionFormatSpecificWorkersJobInstances < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.8'

  DEPRECATED_JOB_CLASSES = %w[
    VirtualRegistries::Container::Cache::MarkEntriesForDestructionWorker
    VirtualRegistries::Packages::Cache::MarkEntriesForDestructionWorker
  ].freeze

  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down; end
end
