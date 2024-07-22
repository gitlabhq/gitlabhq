# frozen_string_literal: true

class ChangePersonalAccessTokensRemoveNotNullExpiresAt < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_b8d60815eb'

  def up
    remove_not_null_constraint :personal_access_tokens, :expires_at
  end

  def down
    add_not_null_constraint :personal_access_tokens, :expires_at, validate: false, constraint_name: CONSTRAINT_NAME
  end
end
