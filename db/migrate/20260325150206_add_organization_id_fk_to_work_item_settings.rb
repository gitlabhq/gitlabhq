# frozen_string_literal: true

class AddOrganizationIdFkToWorkItemSettings < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :work_item_settings, :organizations,
      column: :organization_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :work_item_settings, column: :organization_id
    end
  end
end
