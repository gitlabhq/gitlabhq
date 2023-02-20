# frozen_string_literal: true

class ScheduleVulnerabilitiesFeedbackMigration2 < Gitlab::Database::Migration[2.1]
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
    # rescheduled by 20230203122602_schedule_vulnerabilities_feedback_migration3.rb
  end

  def down
    # no-op
  end
end
