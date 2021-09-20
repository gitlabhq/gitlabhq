# frozen_string_literal: true

class AddExpireAccessTokensToDoorkeeperApplication < Gitlab::Database::Migration[1.0]
  def change
    add_column :oauth_applications, :expire_access_tokens, :boolean, default: false, null: false
  end
end
