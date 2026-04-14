# frozen_string_literal: true

class CreateWorkItemSettings < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  disable_ddl_transaction!

  TABLE_NAME = :work_item_settings

  def up
    create_table TABLE_NAME, if_not_exists: true do |t|
      t.bigint :organization_id, null: true
      t.bigint :namespace_id, null: true
      t.timestamps_with_timezone null: false
      t.boolean :customizable_type_visibility, null: false, default: false
    end

    add_multi_column_not_null_constraint(TABLE_NAME, :namespace_id, :organization_id)

    add_concurrent_index TABLE_NAME, :organization_id,
      unique: true,
      name: 'idx_work_item_settings_on_organization_id',
      where: 'organization_id IS NOT NULL'

    add_concurrent_index TABLE_NAME, :namespace_id,
      unique: true,
      name: 'idx_work_item_settings_on_namespace_id',
      where: 'namespace_id IS NOT NULL'
  end

  def down
    drop_table TABLE_NAME, if_exists: true
  end
end
