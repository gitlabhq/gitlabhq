# frozen_string_literal: true

class AddAttrEncryptedColumnsToWebHook < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :web_hooks, :encrypted_token, :string
    add_column :web_hooks, :encrypted_token_iv, :string

    add_column :web_hooks, :encrypted_url, :string
    add_column :web_hooks, :encrypted_url_iv, :string
  end
end
