# frozen_string_literal: true

class AddNamespacesByTopLevelNamespaceIndex < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_on_namespaces_namespaces_by_top_level_namespace'

  def up
    prepare_async_index :namespaces, '((traversal_ids[1]), type, id)', name: INDEX_NAME
  end

  def down
    unprepare_async_index_by_name :ci_builds, INDEX_NAME
  end
end
