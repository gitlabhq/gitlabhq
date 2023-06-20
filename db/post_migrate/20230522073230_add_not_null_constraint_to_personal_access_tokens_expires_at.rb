# frozen_string_literal: true

class AddNotNullConstraintToPersonalAccessTokensExpiresAt < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_not_null_constraint :personal_access_tokens, :expires_at, validate: false
  end

  def down
    remove_not_null_constraint :personal_access_tokens, :expires_at
  end
end
