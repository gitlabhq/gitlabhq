# frozen_string_literal: true

class FinalizeHkBackfillTraversalIdsToSecurityProjectTrackedContexts < Gitlab::Database::Migration[2.4]
  milestone '19.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillTraversalIdsToSecurityProjectTrackedContexts',
      table_name: :security_project_tracked_contexts,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
