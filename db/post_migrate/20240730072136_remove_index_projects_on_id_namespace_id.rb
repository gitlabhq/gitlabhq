# frozen_string_literal: true

class RemoveIndexProjectsOnIdNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  disable_ddl_transaction!

  INDEX_NAME = 'index_projects_on_id_and_namespace_id'

  def up
    remove_concurrent_index_by_name :projects, INDEX_NAME
  end

  def down
    add_concurrent_index :projects, [:id, :namespace_id], name: INDEX_NAME
  end
end
