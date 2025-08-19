# frozen_string_literal: true

class RemoveSuggestedReviewersWorkers < Gitlab::Database::Migration[2.3]
  DEPRECATED_JOB_CLASSES = %w[
    MergeRequests::CaptureSuggestedReviewersAcceptedWorker
    MergeRequests::FetchSuggestedReviewersWorker
    Projects::DeregisterSuggestedReviewersProjectWorker
    Projects::RegisterSuggestedReviewersProjectWorker
  ]

  disable_ddl_transaction!
  milestone '18.3'

  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down; end
end
