# frozen_string_literal: true

class AddSigningTokenToWebHooks < Gitlab::Database::Migration[2.3]
  milestone '19.0'
  disable_ddl_transaction!

  def up
    add_column :web_hooks, :signing_token, :jsonb, null: true
  end

  def down
    remove_column :web_hooks, :signing_token
  end
end
