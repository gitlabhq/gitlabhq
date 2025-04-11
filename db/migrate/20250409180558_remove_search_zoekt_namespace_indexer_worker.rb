# frozen_string_literal: true

class RemoveSearchZoektNamespaceIndexerWorker < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  disable_ddl_transaction!
  DEPRECATED_JOB_CLASSES = %w[Search::Zoekt::NamespaceIndexerWorker]

  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down; end
end
