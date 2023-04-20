# frozen_string_literal: true

class AddSearchIndexForeignKeyToSearchNamespaceIndexAssignments < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  FK_NAME = 'fk_search_index_id_and_type'

  def up
    add_concurrent_foreign_key :search_namespace_index_assignments, :search_indices,
      name: FK_NAME, column: [:search_index_id, :index_type], target_column: [:id, :type], on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :search_namespace_index_assignments, name: FK_NAME
    end
  end
end
