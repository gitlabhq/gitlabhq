# frozen_string_literal: true

class DropPackagesPackageMetadataTable < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    drop_table :packages_package_metadata
  end

  def down
    create_table :packages_package_metadata do |t|
      t.references :package, index: { unique: true }, null: false, foreign_key: { to_table: :packages_packages, on_delete: :cascade }, type: :integer
      t.binary :metadata, null: false
    end
  end
end
