# frozen_string_literal: true

class AddDiffNotePositionsNamespaceIdForeignKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  def up
    add_concurrent_foreign_key :diff_note_positions,
      :namespaces,
      column: :namespace_id,
      reverse_lock_order: true,
      validate: false
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(:diff_note_positions, column: :namespace_id)
    end
  end
end
