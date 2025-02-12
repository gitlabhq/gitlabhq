# frozen_string_literal: true

class IndexDesignManagementRepositoryStatesOnNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  INDEX_NAME = 'index_design_management_repository_states_on_namespace_id'

  def up
    add_concurrent_index :design_management_repository_states, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :design_management_repository_states, INDEX_NAME
  end
end
