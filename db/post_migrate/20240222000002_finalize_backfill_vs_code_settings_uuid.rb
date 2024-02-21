# frozen_string_literal: true

class FinalizeBackfillVsCodeSettingsUuid < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  TABLE_NAME = 'vs_code_settings'
  MIGRATION_NAME = 'BackfillVsCodeSettingsUuid'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION_NAME,
      table_name: TABLE_NAME,
      column_name: 'id',
      job_arguments: []
    )
  end

  def down
    # no-op
  end
end
