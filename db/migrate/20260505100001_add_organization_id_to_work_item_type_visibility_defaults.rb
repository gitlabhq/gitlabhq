# frozen_string_literal: true

class AddOrganizationIdToWorkItemTypeVisibilityDefaults < Gitlab::Database::Migration[2.3]
  milestone '19.0'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_work_item_type_visibility_defaults_org_or_namespace'

  def up
    with_lock_retries do
      add_column :work_item_type_visibility_defaults, :organization_id, :bigint,
        null: true, if_not_exists: true
    end

    with_lock_retries do
      change_column_null :work_item_type_visibility_defaults, :namespace_id, true
    end

    add_check_constraint(
      :work_item_type_visibility_defaults,
      'num_nonnulls(namespace_id, organization_id) = 1',
      CONSTRAINT_NAME
    )
  end

  def down
    remove_check_constraint :work_item_type_visibility_defaults, CONSTRAINT_NAME

    with_lock_retries do
      change_column_null :work_item_type_visibility_defaults, :namespace_id, false
      remove_column :work_item_type_visibility_defaults, :organization_id, if_exists: true
    end
  end
end
