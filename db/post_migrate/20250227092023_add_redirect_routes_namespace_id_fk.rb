# frozen_string_literal: true

class AddRedirectRoutesNamespaceIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :redirect_routes, :namespaces, column: :namespace_id, on_delete: :cascade
  end

  def down
    remove_foreign_key :redirect_routes, column: :namespace_id
  end
end
