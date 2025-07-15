# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveValidateEpicWorkItemsSyncWorkerJobInstances < Gitlab::Database::Migration[2.3]
  DEPRECATED_JOB_CLASS = %w[
    ValidateEpicWorkItemSyncWorker
  ]
  disable_ddl_transaction!
  milestone '18.2'

  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASS)
  end

  def down; end
end
