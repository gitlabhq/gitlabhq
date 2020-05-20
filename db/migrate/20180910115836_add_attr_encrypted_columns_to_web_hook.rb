# frozen_string_literal: true

class AddAttrEncryptedColumnsToWebHook < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    add_column :web_hooks, :encrypted_token, :string
    add_column :web_hooks, :encrypted_token_iv, :string

    add_column :web_hooks, :encrypted_url, :string
    add_column :web_hooks, :encrypted_url_iv, :string
  end
  # rubocop:enable Migration/PreventStrings
end
