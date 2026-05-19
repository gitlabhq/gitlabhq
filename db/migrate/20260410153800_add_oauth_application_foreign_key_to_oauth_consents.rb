# frozen_string_literal: true

class AddOauthApplicationForeignKeyToOauthConsents < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.0'

  def up
    add_concurrent_foreign_key :oauth_consents, :oauth_applications,
      column: :client_id, target_column: :uid, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :oauth_consents, column: :client_id
    end
  end
end
