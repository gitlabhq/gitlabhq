# frozen_string_literal: true

class RemoveTmpIndexOnRoutesNamespaceIdColumn < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'tmp_index_for_namespace_id_migration_on_routes'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :routes, INDEX_NAME
  end

  def down
    add_concurrent_index :routes,
      :id,
      where: "routes.namespace_id is null and routes.source_type = 'Namespace'",
      name: INDEX_NAME
  end
end
