# frozen_string_literal: true

class AddKeysRelationToSshSignatures < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ssh_signatures, :keys, column: :key_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :ssh_signatures, column: :key_id
    end
  end
end
