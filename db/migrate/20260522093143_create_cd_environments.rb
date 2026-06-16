# frozen_string_literal: true

class CreateCdEnvironments < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  disable_ddl_transaction!

  def up
    create_table :cd_environments, if_not_exists: true do |t|
      t.bigint :group_id
      t.bigint :organization_id
      t.bigint :cluster_agent_id, null: false
      t.timestamps_with_timezone null: false
      t.integer :platform_type, limit: 2, null: false, default: 0
      t.text :name, null: false, limit: 255
      t.text :description, limit: 1024
      t.text :region, limit: 255

      t.index :cluster_agent_id
    end

    add_multi_column_not_null_constraint(:cd_environments, :group_id, :organization_id)

    add_concurrent_index :cd_environments, [:group_id, :name],
      unique: true,
      where: 'group_id IS NOT NULL',
      name: 'uniq_idx_cd_environments_on_group_id_and_name'

    add_concurrent_index :cd_environments, [:organization_id, :name],
      unique: true,
      where: 'organization_id IS NOT NULL',
      name: 'uniq_idx_cd_environments_on_organization_id_and_name'
  end

  def down
    drop_table :cd_environments, if_exists: true
  end
end
