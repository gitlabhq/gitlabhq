# frozen_string_literal: true

class FinalizeTheDeduplicationOfIssuableResourceLinks2 < Gitlab::Database::Migration[2.2]
  DEDUPLICATION_MIGRATION = 'MarkSingleIssuableResourceLinks'

  disable_ddl_transaction!
  milestone '17.9'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: DEDUPLICATION_MIGRATION,
      table_name: :issuable_resource_links,
      column_name: :issue_id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
