# frozen_string_literal: true

class NullifyLastErrorFromProjectMirrorData < Gitlab::Database::Migration[2.1]
  MIGRATION = 'NullifyLastErrorFromProjectMirrorData'
  INTERVAL = 2.minutes
  BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 1_000

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    queue_batched_background_migration(
      MIGRATION,
      :project_mirror_data,
      :id,
      job_interval: INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :project_mirror_data, :id, [])
  end
end
