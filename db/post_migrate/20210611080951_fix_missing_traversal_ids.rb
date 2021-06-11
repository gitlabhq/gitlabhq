# frozen_string_literal: true

class FixMissingTraversalIds < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  ROOTS_MIGRATION = 'BackfillNamespaceTraversalIdsRoots'
  CHILDREN_MIGRATION = 'BackfillNamespaceTraversalIdsChildren'
  DOWNTIME = false
  BATCH_SIZE = 1_000
  SUB_BATCH_SIZE = 50
  DELAY_INTERVAL = 2.minutes
  ROOT_NS_INDEX_NAME = 'tmp_index_namespaces_empty_traversal_ids_with_root_namespaces'
  CHILD_INDEX_NAME = 'tmp_index_namespaces_empty_traversal_ids_with_child_namespaces'

  disable_ddl_transaction!

  def up
    add_concurrent_index :namespaces, :id, where: "parent_id IS NULL AND traversal_ids = '{}'", name: ROOT_NS_INDEX_NAME
    add_concurrent_index :namespaces, :id, where: "parent_id IS NOT NULL AND traversal_ids = '{}'", name: CHILD_INDEX_NAME

    # Personal namespaces and top-level groups
    final_delay = queue_background_migration_jobs_by_range_at_intervals(
      ::Gitlab::BackgroundMigration::BackfillNamespaceTraversalIdsRoots::Namespace.base_query.where("traversal_ids = '{}'"),
       ROOTS_MIGRATION,
       DELAY_INTERVAL,
       batch_size: BATCH_SIZE,
       other_job_arguments: [SUB_BATCH_SIZE],
       track_jobs: true
    )
    final_delay += DELAY_INTERVAL

    # Subgroups
    queue_background_migration_jobs_by_range_at_intervals(
      ::Gitlab::BackgroundMigration::BackfillNamespaceTraversalIdsChildren::Namespace.base_query.where("traversal_ids = '{}'"),
       CHILDREN_MIGRATION,
       DELAY_INTERVAL,
       batch_size: BATCH_SIZE,
       initial_delay: final_delay,
       other_job_arguments: [SUB_BATCH_SIZE],
       track_jobs: true
    )
  end

  def down
    remove_concurrent_index_by_name :namespaces, ROOT_NS_INDEX_NAME
    remove_concurrent_index_by_name :namespaces, CHILD_INDEX_NAME
  end
end
