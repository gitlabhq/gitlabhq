# frozen_string_literal: true

class ScheduleVulnerabilitiesFeedbackMigration3 < Gitlab::Database::Migration[2.1]
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
    # replaced by db/post_migrate/20230209171547_schedule_vulnerabilities_feedback_migration4.rb
    # no-op
  end

  def down
    # no-op
  end
end
