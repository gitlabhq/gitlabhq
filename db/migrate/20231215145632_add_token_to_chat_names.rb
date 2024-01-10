# frozen_string_literal: true

class AddTokenToChatNames < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :chat_names, :encrypted_token, :binary
    add_column :chat_names, :encrypted_token_iv, :binary
  end
end
