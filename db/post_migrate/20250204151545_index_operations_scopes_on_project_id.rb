# frozen_string_literal: true

class IndexOperationsScopesOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  INDEX_NAME = 'index_operations_scopes_on_project_id'

  def up
    add_concurrent_index :operations_scopes, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :operations_scopes, INDEX_NAME
  end
end
