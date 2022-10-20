# frozen_string_literal: true

class RemoveTempIndexNullProjectNamespaceId < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'tmp_index_for_null_project_namespace_id'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :projects, INDEX_NAME
  end

  def down
    add_concurrent_index :projects, :id, name: INDEX_NAME, where: 'project_namespace_id IS NULL'
  end
end
