# frozen_string_literal: true

class IndexRedirectRoutesOnNamespaceId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.10'

  INDEX_NAME = 'index_redirect_routes_on_namespace_id'

  def up
    add_concurrent_index :redirect_routes, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :redirect_routes, INDEX_NAME
  end
end
