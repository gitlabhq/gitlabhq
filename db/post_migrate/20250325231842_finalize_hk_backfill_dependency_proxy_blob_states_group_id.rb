# frozen_string_literal: true

class FinalizeHkBackfillDependencyProxyBlobStatesGroupId < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillDependencyProxyBlobStatesGroupId',
      table_name: :dependency_proxy_blob_states,
      column_name: :dependency_proxy_blob_id,
      job_arguments: [:group_id, :dependency_proxy_blobs, :group_id, :dependency_proxy_blob_id],
      finalize: true
    )
  end

  def down; end
end
