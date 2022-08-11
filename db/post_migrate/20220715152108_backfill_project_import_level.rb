# frozen_string_literal: true

class BackfillProjectImportLevel < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'BackfillProjectImportLevel'
  INTERVAL = 120.seconds

  def up
    queue_batched_background_migration(
      MIGRATION,
      :namespaces,
      :id,
      job_interval: INTERVAL
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :namespaces, :id, [])
  end
end
