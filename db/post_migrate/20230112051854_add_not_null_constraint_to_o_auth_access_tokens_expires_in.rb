# frozen_string_literal: true

class AddNotNullConstraintToOAuthAccessTokensExpiresIn < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    # validate: false ensures that existing records are not affected
    # https://docs.gitlab.com/ee/development/database/not_null_constraints.html#prevent-new-invalid-records-current-release
    add_not_null_constraint :oauth_access_tokens, :expires_in, validate: false
    change_column_default :oauth_access_tokens, :expires_in, 7200
  end

  def down
    remove_not_null_constraint :oauth_access_tokens, :expires_in
    change_column_default :oauth_access_tokens, :expires_in, nil
  end
end
