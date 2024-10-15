# frozen_string_literal: true

class RemoveLegacyOnboardingWorkersJobInstances < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  disable_ddl_transaction!

  DEPRECATED_JOB_CLASSES = %w[
    Onboarding::IssueCreatedWorker
    Onboarding::PipelineCreatedWorker
    Onboarding::ProgressWorker
    Onboarding::UserAddedWorker
  ].freeze

  def up
    # Removes scheduled instances from Sidekiq queues
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes any instances of deprecated workers and cannot be undone.
  end
end
