# frozen_string_literal: true

class CreateWorkItemCustomTypes < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.9'

  TABLE_NAME = :work_item_custom_types

  def up
    create_table TABLE_NAME, if_not_exists: true do |t|
      t.timestamps_with_timezone null: false

      t.bigint :organization_id, null: true
      t.bigint :namespace_id, null: true

      t.integer :icon_name, null: false, default: 0, limit: 2
      t.integer :converted_from_system_defined_type_identifier, null: true, limit: 2

      t.text :name, null: false, limit: 48
    end

    add_multi_column_not_null_constraint(TABLE_NAME, :namespace_id, :organization_id)

    add_concurrent_index TABLE_NAME,
      'organization_id, lower(name)',
      unique: true,
      name: 'idx_work_item_custom_types_on_org_id_and_name',
      where: 'organization_id IS NOT NULL'
    add_concurrent_index TABLE_NAME,
      'namespace_id, lower(name)',
      unique: true,
      name: 'idx_work_item_custom_types_on_ns_id_and_name',
      where: 'namespace_id IS NOT NULL'
  end

  def down
    drop_table TABLE_NAME, if_exists: true
  end
end
