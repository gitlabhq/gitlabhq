# frozen_string_literal: true

class AddIndexToProtectedPendingBuilds < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  INDEX_NAME = 'index_ci_pending_builds_id_on_protected_partial'

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_pending_builds, :id, where: 'protected = true', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_pending_builds, INDEX_NAME
  end
end
