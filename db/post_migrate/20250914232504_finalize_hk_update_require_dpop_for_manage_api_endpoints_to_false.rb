# frozen_string_literal: true

class FinalizeHkUpdateRequireDpopForManageApiEndpointsToFalse < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  TABLE_NAME = :namespace_settings
  COLUMN_NAME = :namespace_id

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'UpdateRequireDpopForManageApiEndpointsToFalse',
      table_name: TABLE_NAME,
      column_name: COLUMN_NAME,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
