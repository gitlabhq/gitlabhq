# frozen_string_literal: true

class AddTempIndexOnNullProjectNamespaceIds < Gitlab::Database::Migration[1.0]
  TMP_INDEX_FOR_NULL_PROJECT_NAMESPACE_ID = 'tmp_index_for_null_project_namespace_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :projects, :id, name: TMP_INDEX_FOR_NULL_PROJECT_NAMESPACE_ID, where: 'project_namespace_id IS NULL'
  end

  def down
    remove_concurrent_index_by_name :projects, name: TMP_INDEX_FOR_NULL_PROJECT_NAMESPACE_ID
  end
end
