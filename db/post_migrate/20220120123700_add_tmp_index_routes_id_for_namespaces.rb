# frozen_string_literal: true

class AddTmpIndexRoutesIdForNamespaces < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'tmp_index_for_namespace_id_migration_on_routes'

  disable_ddl_transaction!

  def up
    # Temporary index to be removed in 14.9
    # https://gitlab.com/gitlab-org/gitlab/-/issues/352353
    add_concurrent_index :routes, :id, where: "routes.namespace_id is null and routes.source_type = 'Namespace'", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :routes, INDEX_NAME
  end
end
