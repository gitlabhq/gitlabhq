# frozen_string_literal: true

class AddForeignKeyOnKeyIdToTagSshSignatures < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :tag_ssh_signatures, :keys, column: :key_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key :tag_ssh_signatures, column: :key_id
    end
  end
end
