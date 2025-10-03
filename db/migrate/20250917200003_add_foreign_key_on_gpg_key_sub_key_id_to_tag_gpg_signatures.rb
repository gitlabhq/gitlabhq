# frozen_string_literal: true

class AddForeignKeyOnGpgKeySubKeyIdToTagGpgSignatures < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :tag_gpg_signatures, :gpg_key_subkeys, column: :gpg_key_subkey_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :tag_gpg_signatures, column: :gpg_key_subkey_id
    end
  end
end
