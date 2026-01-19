# frozen_string_literal: true

class FinalizeHkBackfillMissingNamespaceDetails < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillMissingNamespaceDetails',
      table_name: :namespaces,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
