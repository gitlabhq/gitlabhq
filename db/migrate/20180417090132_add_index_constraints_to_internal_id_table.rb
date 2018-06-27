class AddIndexConstraintsToInternalIdTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :internal_ids, [:usage, :namespace_id], unique: true, where: 'namespace_id IS NOT NULL'

    replace_index(:internal_ids, [:usage, :project_id], name: 'index_internal_ids_on_usage_and_project_id') do
      add_concurrent_index :internal_ids, [:usage, :project_id], unique: true, where: 'project_id IS NOT NULL'
    end

    add_concurrent_foreign_key :internal_ids, :namespaces, column: :namespace_id, on_delete: :cascade
  end

  def down
    remove_concurrent_index :internal_ids, [:usage, :namespace_id]

    replace_index(:internal_ids, [:usage, :project_id], name: 'index_internal_ids_on_usage_and_project_id') do
      add_concurrent_index :internal_ids, [:usage, :project_id], unique: true
    end

    remove_foreign_key :internal_ids, column: :namespace_id
  end

  private
  def replace_index(table, columns, name:)
    temporary_name = "#{name}_old"

    if index_exists?(table, columns, name: name)
      rename_index table, name, temporary_name
    end

    yield

    remove_concurrent_index_by_name table, temporary_name
  end
end
