# frozen_string_literal: true

class RemoveZoektNamespaceInitialIndexingWorker < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!
  DEPRECATED_JOB_CLASSES = %w[Search::Zoekt::NamespaceInitialIndexingWorker]

  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down; end
end
