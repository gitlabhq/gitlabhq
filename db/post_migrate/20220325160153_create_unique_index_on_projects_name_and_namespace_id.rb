# frozen_string_literal: true

class CreateUniqueIndexOnProjectsNameAndNamespaceId < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'unique_projects_on_name_namespace_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :projects, [:name, :namespace_id], unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :projects, INDEX_NAME
  end
end
