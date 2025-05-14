# frozen_string_literal: true

class FinalizeHkBackfillDependencyProxyManifestStatesGroupId < Gitlab::Database::Migration[2.2]
  milestone '18.1'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillDependencyProxyManifestStatesGroupId',
      table_name: :dependency_proxy_manifest_states,
      column_name: :dependency_proxy_manifest_id,
      job_arguments: [:group_id, :dependency_proxy_manifests, :group_id, :dependency_proxy_manifest_id],
      finalize: true
    )
  end

  def down; end
end
