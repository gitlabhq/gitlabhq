# frozen_string_literal: true

class AddCustomHeadersToWebHook < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '16.11'

  def change
    add_column :web_hooks, :encrypted_custom_headers, :binary
    add_column :web_hooks, :encrypted_custom_headers_iv, :binary
  end
end
