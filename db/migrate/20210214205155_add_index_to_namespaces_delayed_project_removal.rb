# frozen_string_literal: true

class AddIndexToNamespacesDelayedProjectRemoval < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'tmp_idx_on_namespaces_delayed_project_removal'

  disable_ddl_transaction!

  def up
    add_concurrent_index :namespaces, :id, name: INDEX_NAME, where: 'delayed_project_removal = TRUE'
  end

  def down
    remove_concurrent_index_by_name :namespaces, INDEX_NAME
  end
end
