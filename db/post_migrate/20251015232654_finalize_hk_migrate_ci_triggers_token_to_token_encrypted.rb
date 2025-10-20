# frozen_string_literal: true

class FinalizeHkMigrateCiTriggersTokenToTokenEncrypted < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'MigrateCiTriggersTokenToTokenEncrypted',
      table_name: :ci_triggers,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
