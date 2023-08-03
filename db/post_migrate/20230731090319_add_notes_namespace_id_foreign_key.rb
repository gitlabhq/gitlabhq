# frozen_string_literal: true

class AddNotesNamespaceIdForeignKey < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_notes_on_namespace_id'

  def up
    add_concurrent_index :notes, :namespace_id, name: INDEX_NAME
    add_concurrent_foreign_key :notes, :namespaces,
      column: :namespace_id,
      on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :notes, column: :namespace_id
    remove_concurrent_index_by_name :notes, INDEX_NAME
  end
end
