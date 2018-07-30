# frozen_string_literal: true

class CreateSoftwareLicensePolicies < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_software_license_policies_unique_per_project'

  disable_ddl_transaction!

  def up
    create_table :software_license_policies do |t|
      t.references :project, index: false, foreign_key: { on_delete: :cascade }, null: false
      t.references :software_license, index: false, foreign_key: { on_delete: :cascade }, null: false
      t.integer :approval_status, null: false, default: 0 # Defaults to blacklisted
    end

    add_concurrent_index :software_license_policies,
      [:project_id, :software_license_id],
      unique: true,
      name: INDEX_NAME
  end

  def down
    if foreign_keys_for(:software_license_policies, :project_id).any?
      remove_foreign_key :software_license_policies, column: :project_id
    end

    if foreign_keys_for(:software_license_policies, :software_license_id).any?
      remove_foreign_key :software_license_policies, column: :software_license_id
    end

    if index_exists?(:software_license_policies, [:project_id, :software_license_id])
      remove_concurrent_index :software_license_policies, [:project_id, :software_license_id]
    end

    if table_exists?(:software_license_policies)
      drop_table :software_license_policies
    end
  end
end
