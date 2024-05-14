# frozen_string_literal: true

class FinalizeBackfillOnboardingStatusStepUrl < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.11'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # params match the queueing migration in db/post_migrate/20240226174509_queue_backfill_onboarding_status_step_url.rb
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillOnboardingStatusStepUrl',
      table_name: :users,
      column_name: :id,
      job_arguments: []
    )
  end

  def down
    # no-op
  end
end
