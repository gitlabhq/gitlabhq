# frozen_string_literal: true

class AddTokenDigestToPersonalAccessTokens < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    change_column :personal_access_tokens, :token, :string, null: true

    add_column :personal_access_tokens, :token_digest, :string
  end

  def down
    remove_column :personal_access_tokens, :token_digest

    change_column :personal_access_tokens, :token, :string, null: false
  end
end
