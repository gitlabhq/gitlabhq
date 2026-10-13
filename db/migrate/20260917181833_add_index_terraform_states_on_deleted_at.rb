# frozen_string_literal: true

class AddIndexTerraformStatesOnDeletedAt < Gitlab::Database::Migration[2.3]
  milestone '19.5'
  disable_ddl_transaction!
  INDEX_NAME = 'index_terraform_states_on_deleted_at'

  def up
    add_concurrent_index :terraform_states, :deleted_at,
      name: INDEX_NAME,
      where: 'deleted_at IS NOT NULL'
  end

  def down
    remove_concurrent_index_by_name :terraform_states, INDEX_NAME
  end
end
