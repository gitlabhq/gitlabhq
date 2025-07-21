# frozen_string_literal: true

class FinalizeEncryptMissedCiRunnerTokens < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'EncryptMissedCiRunnerTokens',
      table_name: :ci_runners,
      column_name: :id,
      job_arguments: []
    )
  end

  def down
    # nothing to do
  end
end
