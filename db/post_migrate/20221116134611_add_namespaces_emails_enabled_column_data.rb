# frozen_string_literal: true
class AddNamespacesEmailsEnabledColumnData < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'AddNamespacesEmailsEnabledColumnData'
  DELAY_INTERVAL = 2.minutes.to_i
  BATCH_SIZE = 200
  MAX_BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 20

  def up
    queue_batched_background_migration(
      MIGRATION,
      :namespaces,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      gitlab_schema: :gitlab_main
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :namespaces, :id, [])
  end
end
