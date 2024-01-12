# frozen_string_literal: true

class AddTokenToChatNames < Gitlab::Database::Migration[2.2]
  enable_lock_retries!

  milestone '16.6'

  # This migration was added as different filenames across GitLab
  # versions in security releases:
  #
  # 16.8 - db/migrate/20231123160255_add_token_to_chat_names.rb
  # 16.7 - db/migrate/20231219120134_add_token_to_chat_names.rb
  # 16.6 - db/migrate/20231215135014_add_token_to_chat_names.rb
  # 16.5 - db/migrate/20231215145632_add_token_to_chat_names.rb
  #
  # This migration needs to be idempotent to prevent upgrade failures.
  def up
    add_column :chat_names, :encrypted_token, :binary unless column_exists?(:chat_names, :encrypted_token)
    add_column :chat_names, :encrypted_token_iv, :binary unless column_exists?(:chat_names, :encrypted_token_iv)
  end

  def down
    remove_column :chat_names, :encrypted_token, :binary if column_exists?(:chat_names, :encrypted_token)
    remove_column :chat_names, :encrypted_token_iv, :binary if column_exists?(:chat_names, :encrypted_token_iv)
  end
end
