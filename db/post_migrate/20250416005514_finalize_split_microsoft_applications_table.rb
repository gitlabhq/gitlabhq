# frozen_string_literal: true

class FinalizeSplitMicrosoftApplicationsTable < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "SplitMicrosoftApplicationsTable"

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :system_access_microsoft_applications,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
