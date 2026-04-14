# frozen_string_literal: true

class AddIndexCreatedAtToCiPendingBuilds < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  INDEX_NAME = 'index_ci_pending_builds_on_created_at_and_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_pending_builds, [:created_at, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_pending_builds, INDEX_NAME
  end
end
