# frozen_string_literal: true

class AddUserForeignKeyToOauthConsents < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.0'

  def up
    add_concurrent_foreign_key :oauth_consents, :users,
      column: :user_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :oauth_consents, column: :user_id
    end
  end
end
