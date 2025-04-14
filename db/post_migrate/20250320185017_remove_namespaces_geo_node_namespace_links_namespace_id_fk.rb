# frozen_string_literal: true

class RemoveNamespacesGeoNodeNamespaceLinksNamespaceIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  disable_ddl_transaction!

  FOREIGN_KEY_NAME = "fk_rails_41ff5fb854"

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:geo_node_namespace_links, :namespaces,
        name: FOREIGN_KEY_NAME, reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:geo_node_namespace_links, :namespaces,
      name: FOREIGN_KEY_NAME, column: :namespace_id,
      target_column: :id, on_delete: :cascade)
  end
end
