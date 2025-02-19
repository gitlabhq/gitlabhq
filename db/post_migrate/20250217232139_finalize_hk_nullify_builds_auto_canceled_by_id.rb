# frozen_string_literal: true

class FinalizeHkNullifyBuildsAutoCanceledById < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'NullifyBuildsAutoCanceledById',
      table_name: :p_ci_builds,
      column_name: :auto_canceled_by_id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
