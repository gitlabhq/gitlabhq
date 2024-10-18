# frozen_string_literal: true

class QueueRestoreOptInToGitlabCom < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  # https://gitlab.com/gitlab-com/gl-infra/production/-/issues/18367
  TEMPORARY_TABLE_NAME = 'temp_user_details_issue18240'
  MIGRATION = "RestoreOptInToGitlabCom"
  DELAY_INTERVAL = 2.minutes
  TABLE_NAME = :user_details
  BATCH_COLUMN = :user_id
  BATCH_SIZE = 3_000
  SUB_BATCH_SIZE = 250
  MAX_BATCH_SIZE = 10_000

  def up
    return unless should_run?

    queue_batched_background_migration(
      MIGRATION,
      TABLE_NAME,
      BATCH_COLUMN,
      TEMPORARY_TABLE_NAME,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE
    )
  end

  def down
    return unless should_run?

    delete_batched_background_migration(MIGRATION, TABLE_NAME, BATCH_COLUMN, [TEMPORARY_TABLE_NAME])
  end

  private

  def should_run?
    Gitlab.com_except_jh? && ApplicationRecord.connection.table_exists?(TEMPORARY_TABLE_NAME)
  end
end
