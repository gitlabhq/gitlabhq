# frozen_string_literal: true

class AddPatFkToPatGranularScopes < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.4'

  def up
    add_concurrent_foreign_key :personal_access_token_granular_scopes, :personal_access_tokens,
      column: :personal_access_token_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :personal_access_token_granular_scopes, column: :personal_access_token_id
    end
  end
end
