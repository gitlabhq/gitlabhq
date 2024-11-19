# frozen_string_literal: true

class FinalizeBackfillDoraDailyMetricsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillDoraDailyMetricsProjectId',
      table_name: :dora_daily_metrics,
      column_name: :id,
      job_arguments: [:project_id, :environments, :project_id, :environment_id],
      finalize: true
    )
  end

  def down; end
end
