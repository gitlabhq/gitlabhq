# frozen_string_literal: true

class AddCiTriggersEncryptedToken < Gitlab::Database::Migration[2.1]
  def up
    add_column :ci_triggers, :encrypted_token, :binary
    add_column :ci_triggers, :encrypted_token_iv, :binary
  end

  def down
    remove_column :ci_triggers, :encrypted_token
    remove_column :ci_triggers, :encrypted_token_iv
  end
end
