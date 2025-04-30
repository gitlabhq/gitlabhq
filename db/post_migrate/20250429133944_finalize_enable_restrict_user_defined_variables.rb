# frozen_string_literal: true

class FinalizeEnableRestrictUserDefinedVariables < Gitlab::Database::Migration[2.3]
  milestone '18.0'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "EnableRestrictUserDefinedVariables"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :project_ci_cd_settings,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
