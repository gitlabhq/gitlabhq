# frozen_string_literal: true

class AddOrganizationIdColumnToWebHooks < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'

  def up
    with_lock_retries do
      add_column :web_hooks, :organization_id, :bigint, if_not_exists: true
    end

    add_concurrent_foreign_key(
      :web_hooks,
      :organizations,
      column: :organization_id,
      foreign_key: true,
      on_delete: :cascade,
      validate: false
    )
  end

  def down
    with_lock_retries do
      remove_column :web_hooks, :organization_id, if_exists: true
    end
  end
end
