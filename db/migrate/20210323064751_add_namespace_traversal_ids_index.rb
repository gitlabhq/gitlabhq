# frozen_string_literal: true

class AddNamespaceTraversalIdsIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_namespaces_on_traversal_ids'

  disable_ddl_transaction!

  def up
    add_concurrent_index :namespaces, :traversal_ids, using: :gin, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :namespaces, INDEX_NAME
  end
end
