# frozen_string_literal: true

class QueueMigrateProjectAuthorizations < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  TABLE_NAME = 'project_authorizations'
  MIGRATION = "MigrateProjectAuthorizations"

  def up
    max_user_id, max_project_id, max_access_level = define_batchable_model(TABLE_NAME)
                            .order(user_id: :desc, project_id: :desc, access_level: :desc)
                            .pick(:user_id, :project_id, :access_level)

    max_user_id ||= 0
    max_project_id ||= 0
    max_access_level ||= 0

    Gitlab::Database::BackgroundMigration::BatchedMigration.create!(
      gitlab_schema: :gitlab_main,
      job_class_name: MIGRATION,
      job_arguments: [],
      table_name: TABLE_NAME.to_sym,
      column_name: :user_id,
      min_cursor: [0, 0, 0],
      max_cursor: [max_user_id, max_project_id, max_access_level],
      interval: BATCH_MIN_DELAY,
      pause_ms: 100,
      batch_class_name: BATCH_CLASS_NAME,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      status_event: :execute
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :project_authorizations, :user_id, [])
  end
end
