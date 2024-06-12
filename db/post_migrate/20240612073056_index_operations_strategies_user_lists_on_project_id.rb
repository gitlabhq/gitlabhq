# frozen_string_literal: true

class IndexOperationsStrategiesUserListsOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_operations_strategies_user_lists_on_project_id'

  def up
    add_concurrent_index :operations_strategies_user_lists, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :operations_strategies_user_lists, INDEX_NAME
  end
end
