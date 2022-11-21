# frozen_string_literal: true

class RemoveNamespacesTmpProjectIdColumn < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'tmp_index_on_tmp_project_id_on_namespaces'

  def up
    with_lock_retries do
      remove_column :namespaces, :tmp_project_id if column_exists?(:namespaces, :tmp_project_id)
    end
  end

  def down
    unless column_exists?(:namespaces, :tmp_project_id)
      with_lock_retries do
        # rubocop:disable Migration/SchemaAdditionMethodsNoPost, Migration/AddColumnsToWideTables
        add_column :namespaces, :tmp_project_id, :integer
        # rubocop:enable Migration/SchemaAdditionMethodsNoPost, Migration/AddColumnsToWideTables
      end
    end

    add_concurrent_foreign_key :namespaces, :projects, column: :tmp_project_id

    add_concurrent_index :namespaces, :tmp_project_id, name: INDEX_NAME, unique: true
  end
end
