# frozen_string_literal: true

class QueueBackfillPackagesNugetSymbolStatesProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.11'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillPackagesNugetSymbolStatesProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :packages_nuget_symbol_states,
      :packages_nuget_symbol_id,
      :project_id,
      :packages_nuget_symbols,
      :project_id,
      :packages_nuget_symbol_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :packages_nuget_symbol_states,
      :packages_nuget_symbol_id,
      [
        :project_id,
        :packages_nuget_symbols,
        :project_id,
        :packages_nuget_symbol_id
      ]
    )
  end
end
