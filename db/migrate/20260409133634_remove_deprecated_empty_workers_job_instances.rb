# frozen_string_literal: true

class RemoveDeprecatedEmptyWorkersJobInstances < Gitlab::Database::Migration[2.3]
  milestone '18.11'
  disable_ddl_transaction!

  DEPRECATED_JOB_CLASSES = %w[
    Epics::NewEpicIssueWorker
    RefreshLicenseComplianceChecksWorker
    Authn::SyncGroupScimIdentityRecordWorker
    Authn::SyncGroupScimTokenRecordWorker
    Authn::SyncScimIdentityRecordWorker
    Authn::SyncScimTokenRecordWorker
    Gitlab::GithubImport::Stage::ImportNotesWorker
    Gitlab::GithubImport::Stage::ImportPullRequestsMergedByWorker
    Gitlab::GithubImport::Stage::ImportPullRequestsReviewRequestsWorker
    Gitlab::GithubImport::Stage::ImportPullRequestsReviewsWorker
  ]

  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down; end
end
