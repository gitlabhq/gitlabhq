# frozen_string_literal: true

class AddOrganizationIdFkToWorkItemCustomTypes < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :work_item_custom_types, :organizations, column: :organization_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :work_item_custom_types, column: :organization_id
    end
  end
end
