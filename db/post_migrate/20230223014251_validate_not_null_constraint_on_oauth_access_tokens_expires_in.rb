# frozen_string_literal: true

class ValidateNotNullConstraintOnOauthAccessTokensExpiresIn < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    validate_not_null_constraint :oauth_access_tokens, :expires_in
  end

  def down
    # no-op
  end
end
