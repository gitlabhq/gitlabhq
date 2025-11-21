# frozen_string_literal: true

class RemoveEncryptedTokenFromCiTrigger < Gitlab::Database::Migration[2.3]
  milestone '18.7'
  disable_ddl_transaction!

  def up
    remove_column :ci_triggers, :encrypted_token, if_exists: true
    remove_column :ci_triggers, :encrypted_token_iv, if_exists: true
  end

  def down
    add_column :ci_triggers, :encrypted_token, :binary, if_not_exists: true
    add_column :ci_triggers, :encrypted_token_iv, :binary, if_not_exists: true
  end
end
