# frozen_string_literal: true

class CreatePackagesConanFileMetadata < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :packages_conan_file_metadata do |t|
      t.references :package_file, index: { unique: true }, null: false, foreign_key: { to_table: :packages_package_files, on_delete: :cascade }, type: :bigint
      t.timestamps_with_timezone
      t.string "recipe_revision", null: false, default: "0", limit: 255
      t.string "package_revision", limit: 255
      t.string "conan_package_reference", limit: 255
      t.integer "conan_file_type", limit: 2, null: false
    end
  end
end
