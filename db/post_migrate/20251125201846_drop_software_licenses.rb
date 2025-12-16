# frozen_string_literal: true

class DropSoftwareLicenses < Gitlab::Database::Migration[2.3]
  milestone '18.7'
  disable_ddl_transaction!

  def up
    drop_table :software_licenses
  end

  def down
    create_table :software_licenses do |t|
      t.string :name, null: false
      t.string :spdx_identifier, null: true, limit: 255
    end

    add_concurrent_index :software_licenses, 'LOWER(name)', name: 'idx_software_licenses_lower_name'
    add_concurrent_index :software_licenses, :spdx_identifier, name: 'index_software_licenses_on_spdx_identifier'
    add_concurrent_index :software_licenses, :name, unique: true, name: 'index_software_licenses_on_unique_name'
  end
end
