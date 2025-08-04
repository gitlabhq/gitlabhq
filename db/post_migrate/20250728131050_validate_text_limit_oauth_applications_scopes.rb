# frozen_string_literal: true

class ValidateTextLimitOauthApplicationsScopes < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  def up
    validate_text_limit :oauth_applications, :scopes
  end

  def down
    # No-op: validation removal is handled by constraint removal
  end
end
