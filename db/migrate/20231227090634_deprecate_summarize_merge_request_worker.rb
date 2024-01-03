# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class DeprecateSummarizeMergeRequestWorker < Gitlab::Database::Migration[2.2]
  DEPRECATED_JOB_CLASSES = %w[
    MergeRequests::Llm::SummarizeMergeRequestWorker
  ]

  milestone '16.8'
  disable_ddl_transaction!

  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes any instances of deprecated workers and cannot be undone.
  end
end
