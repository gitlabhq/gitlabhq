# frozen_string_literal: true

class FinalizeBackfillOnboardingStatusRegistrationObjective < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # no-op
    # This migration finalization was changed to a no-op because the job arguments did not match
    # the batched background migration configuration, causing database testing pipeline failures.
    # Original MR: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/195690
    # Error: Could not find batched background migration for the given configuration with job_arguments: []
  end

  def down
    # no-op
  end
end
