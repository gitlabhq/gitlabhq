# frozen_string_literal: true

class DropNotesArchivedNamespacesForeignKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :notes_archived, :namespaces, column: :namespace_id, reverse_lock_order: true
    end
  end

  def down
    add_concurrent_foreign_key :notes_archived, :namespaces, column: :namespace_id, on_delete: :cascade
  end
end
