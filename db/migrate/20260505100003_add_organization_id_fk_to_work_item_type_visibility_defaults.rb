# frozen_string_literal: true

class AddOrganizationIdFkToWorkItemTypeVisibilityDefaults < Gitlab::Database::Migration[2.3]
  milestone '19.0'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :work_item_type_visibility_defaults,
      :organizations,
      column: :organization_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :work_item_type_visibility_defaults, column: :organization_id
    end
  end
end
