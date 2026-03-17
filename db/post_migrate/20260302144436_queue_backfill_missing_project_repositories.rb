# frozen_string_literal: true

class QueueBackfillMissingProjectRepositories < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  # This is the schema of the table this migration modifies (project_repositories). It loops through projects, in the
  # gitlab_main_org schema with which cross-joins are allowed
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell_local

  MIGRATION = "BackfillMissingProjectRepositories"
  SUB_BATCH_SIZE = 500

  def up
    queue_batched_background_migration(
      MIGRATION,
      :projects,
      :id,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :projects, :id, [])
  end
end
