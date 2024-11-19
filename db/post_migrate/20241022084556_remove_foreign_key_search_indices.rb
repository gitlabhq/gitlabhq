# frozen_string_literal: true

class RemoveForeignKeySearchIndices < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  FK_NAME = 'fk_search_index_id_and_type'

  def up
    with_lock_retries do
      remove_foreign_key :search_namespace_index_assignments, name: FK_NAME
    end
  end

  def down
    add_concurrent_foreign_key :search_namespace_index_assignments, :search_indices,
      name: FK_NAME, column: [:search_index_id, :index_type], target_column: [:id, :type], on_delete: :cascade
  end
end
