# frozen_string_literal: true

class CreatePackagesNugetSymbols < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    create_table :packages_nuget_symbols do |t|
      t.timestamps_with_timezone null: false

      t.references :package,
        foreign_key: { to_table: :packages_packages, on_delete: :nullify },
        index: true,
        type: :bigint
      t.integer :size, null: false
      t.integer :file_store, default: 1, limit: 2
      t.text :file, null: false, limit: 255
      t.text :file_path, null: false, limit: 255
      t.text :signature, null: false, limit: 255
      t.text :object_storage_key, null: false, limit: 255, index: { unique: true }

      t.index [:signature, :file_path], unique: true
    end
  end
end
