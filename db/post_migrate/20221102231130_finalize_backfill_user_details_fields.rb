# frozen_string_literal: true

class FinalizeBackfillUserDetailsFields < Gitlab::Database::Migration[2.0]
  BACKFILL_MIGRATION = 'BackfillUserDetailsFields'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # If the 20230116160904_remove_user_details_fields_from_user.rb migration already ran,
    # finalizing this background migration will fail.
    return unless column_exists?(:users, :linkedin)

    ensure_batched_background_migration_is_finished(
      job_class_name: BACKFILL_MIGRATION,
      table_name: :users,
      column_name: :id,
      job_arguments: [],
      finalize: true)
  end

  def down; end
end
