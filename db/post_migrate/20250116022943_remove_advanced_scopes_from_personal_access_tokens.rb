# frozen_string_literal: true

class RemoveAdvancedScopesFromPersonalAccessTokens < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  def up
    remove_column :personal_access_tokens, :advanced_scopes, if_exists: true
  end

  def down
    add_column :personal_access_tokens, :advanced_scopes, :text, if_not_exists: true

    add_text_limit :personal_access_tokens, :advanced_scopes, 4096
  end
end
