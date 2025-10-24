# frozen_string_literal: true

class AddNoteDiffFilesNamespaceIdForeignKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  def up
    add_concurrent_foreign_key :note_diff_files,
      :namespaces,
      column: :namespace_id,
      reverse_lock_order: true,
      validate: false
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(:note_diff_files, column: :namespace_id)
    end
  end
end
