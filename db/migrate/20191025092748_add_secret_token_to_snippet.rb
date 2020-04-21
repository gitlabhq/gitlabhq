# frozen_string_literal: true

class AddSecretTokenToSnippet < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    add_column :snippets, :encrypted_secret_token, :string, limit: 255
    add_column :snippets, :encrypted_secret_token_iv, :string, limit: 255
  end
  # rubocop:enable Migration/PreventStrings
end
