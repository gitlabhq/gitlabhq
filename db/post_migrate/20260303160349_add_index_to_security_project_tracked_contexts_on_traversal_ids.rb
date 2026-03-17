# frozen_string_literal: true

class AddIndexToSecurityProjectTrackedContextsOnTraversalIds < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  disable_ddl_transaction!

  INDEX_NAME = 'index_security_project_tracked_contexts_on_traversal_ids_id'

  def up
    add_concurrent_index :security_project_tracked_contexts, [:traversal_ids, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :security_project_tracked_contexts, INDEX_NAME
  end
end
