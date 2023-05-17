# frozen_string_literal: true

class FinishResetDuplicateCiRunnersTokenEncryptedValues < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'ResetDuplicateCiRunnersTokenEncryptedValues',
      table_name: :ci_runners,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
