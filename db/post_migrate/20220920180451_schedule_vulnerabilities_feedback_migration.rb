# frozen_string_literal: true

class ScheduleVulnerabilitiesFeedbackMigration < Gitlab::Database::Migration[2.0]
  MIGRATION = 'MigrateVulnerabilitiesFeedbackToVulnerabilitiesStateTransition'
  TABLE_NAME = :vulnerability_feedback
  BATCH_COLUMN = :id
  DELAY_INTERVAL = 5.minutes
  BATCH_SIZE = 250
  MAX_BATCH_SIZE = 250
  SUB_BATCH_SIZE = 50

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # no-op
    # Removing this migration due to subtransactions created. See discussion in
    # https://gitlab.com/gitlab-org/gitlab/-/issues/386494#note_1217986034
  end

  def down
    # no-op
  end
end
