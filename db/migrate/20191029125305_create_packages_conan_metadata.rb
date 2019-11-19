# frozen_string_literal: true

class CreatePackagesConanMetadata < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :packages_conan_metadata do |t|
      t.references :package, index: { unique: true }, null: false, foreign_key: { to_table: :packages_packages, on_delete: :cascade }, type: :bigint
      t.timestamps_with_timezone
      t.string "package_username", null: false, limit: 255
      t.string "package_channel", null: false, limit: 255
    end
  end
end
