# frozen_string_literal: true

class CreatePackageMetadatum < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :packages_package_metadata do |t|
      t.references :package, index: { unique: true }, null: false, foreign_key: { to_table: :packages_packages, on_delete: :cascade }, type: :integer
      t.binary :metadata, null: false
    end
  end
end
