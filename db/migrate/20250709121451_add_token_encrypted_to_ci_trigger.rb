# frozen_string_literal: true

class AddTokenEncryptedToCiTrigger < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  def up
    with_lock_retries do
      add_column :ci_triggers, :token_encrypted, :text
    end

    add_text_limit :ci_triggers, :token_encrypted, 255
  end

  def down
    with_lock_retries do
      remove_column :ci_triggers, :token_encrypted
    end
  end
end
