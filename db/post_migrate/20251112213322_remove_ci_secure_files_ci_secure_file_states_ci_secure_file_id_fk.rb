# frozen_string_literal: true

class RemoveCiSecureFilesCiSecureFileStatesCiSecureFileIdFk < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  FOREIGN_KEY_NAME = "fk_rails_5adba40c5f"

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:ci_secure_file_states, :ci_secure_files,
        name: FOREIGN_KEY_NAME, reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:ci_secure_file_states, :ci_secure_files,
      name: FOREIGN_KEY_NAME, column: :ci_secure_file_id,
      target_column: :id, on_delete: :cascade)
  end
end
