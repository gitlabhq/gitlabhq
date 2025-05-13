# frozen_string_literal: true

class AddOrganizationIdFkToIntegrations < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :integrations, :organization_id, :bigint, if_not_exists: true
    end

    add_concurrent_foreign_key(
      :integrations,
      :organizations,
      column: :organization_id,
      foreign_key: true,
      on_delete: :cascade,
      validate: false
    )
  end

  def down
    with_lock_retries do
      remove_column :integrations, :organization_id, if_exists: true
    end
  end
end
