# frozen_string_literal: true

class RemoveObsoleteAiUsageBackfillWorkers < Gitlab::Database::Migration[2.3]
  milestone '18.5'
  disable_ddl_transaction!

  DEPRECATED_JOB_CLASSES = %w[
    CodeSuggestionsEventsBackfillWorker
    DuoChatEventsBackfillWorker
  ]

  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes any instances of deprecated workers and cannot be undone.
  end
end
