# frozen_string_literal: true

class AddNamespaceTraversalIdsToCiPendingBuilds < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    add_column :ci_pending_builds, :namespace_traversal_ids, :integer, array: true, default: []
  end
end
