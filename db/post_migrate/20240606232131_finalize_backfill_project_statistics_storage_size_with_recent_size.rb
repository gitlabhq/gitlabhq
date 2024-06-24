# frozen_string_literal: true

class FinalizeBackfillProjectStatisticsStorageSizeWithRecentSize < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillProjectStatisticsStorageSizeWithRecentSize',
      table_name: :project_statistics,
      column_name: :project_id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
