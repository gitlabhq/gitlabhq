# frozen_string_literal: true

class FinalizeCleanSubscriptionsUserIdColumnBbm < Gitlab::Database::Migration[2.3]
  MIGRATION = 'CleanSubscriptionsUserIdColumn'

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_user
  milestone '18.6'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :subscriptions,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
