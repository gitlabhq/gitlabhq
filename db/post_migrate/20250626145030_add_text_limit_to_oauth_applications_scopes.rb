# frozen_string_literal: true

class AddTextLimitToOauthApplicationsScopes < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.2'

  def up
    # Add constraint without validation to ensure consistency while maintaining compatibility
    # Validation will be enabled in a follow-up migration in 18.3
    add_text_limit :oauth_applications, :scopes, 2048, validate: false
  end

  def down
    remove_text_limit :oauth_applications, :scopes
  end
end
