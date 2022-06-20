# frozen_string_literal: true

class AddUrlVarsToWebHook < Gitlab::Database::Migration[2.0]
  def change
    add_column :web_hooks, :encrypted_url_variables, :binary
    add_column :web_hooks, :encrypted_url_variables_iv, :binary
  end
end
