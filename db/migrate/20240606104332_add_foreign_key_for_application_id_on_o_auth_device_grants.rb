# frozen_string_literal: true

class AddForeignKeyForApplicationIdOnOAuthDeviceGrants < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(
      :oauth_device_grants,
      :oauth_applications,
      column: :application_id,
      on_delete: :cascade
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key :oauth_device_grants, column: :application_id
    end
  end
end
