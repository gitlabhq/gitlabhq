# frozen_string_literal: true

class AddGinIndexOnPendingBuildsNamespaceTraversalIds < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_gin_ci_pending_builds_on_namespace_traversal_ids'

  def up
    add_concurrent_index :ci_pending_builds, :namespace_traversal_ids, name: INDEX_NAME, using: :gin
  end

  def down
    remove_concurrent_index_by_name :ci_pending_builds, INDEX_NAME
  end
end
