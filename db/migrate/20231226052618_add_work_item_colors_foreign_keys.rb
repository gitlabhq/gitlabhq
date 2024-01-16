# frozen_string_literal: true

class AddWorkItemColorsForeignKeys < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.8'

  TABLE = :work_item_colors

  def up
    add_concurrent_index TABLE, :namespace_id, name: "wi_colors_namespace_id_index"
    add_concurrent_foreign_key TABLE, :namespaces, column: :namespace_id, on_delete: :nullify
  end

  def down
    remove_concurrent_index_by_name TABLE, name: "wi_colors_namespace_id_index"
    remove_foreign_key_if_exists TABLE, :namespaces, column: :namespace_id
  end
end
