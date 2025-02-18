# frozen_string_literal: true

class FinalizeTheDeduplicationOfIssuableResourceLinks3 < Gitlab::Database::Migration[2.2]
  DELETION_MIGRATION = 'DeleteDuplicateIssuableResourceLinks'

  disable_ddl_transaction!
  milestone '17.9'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: DELETION_MIGRATION,
      table_name: :issuable_resource_links,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
