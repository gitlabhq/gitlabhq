# frozen_string_literal: true

class FinalizeRedirectRoutesShardingKeyBackfill < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillNamespacesRedirectRoutesNamespaceId',
      table_name: :redirect_routes,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillProjectsRedirectRoutesNamespaceId',
      table_name: :redirect_routes,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
    ensure_batched_background_migration_is_finished(
      job_class_name: 'DeleteOrphanRedirectRoutesRows',
      table_name: :redirect_routes,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
