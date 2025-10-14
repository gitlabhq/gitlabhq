# frozen_string_literal: true

class AddCargoMetadataTableAndIndex < Gitlab::Database::Migration[2.3]
  milestone '18.5'
  disable_ddl_transaction!

  INDEX_NAME = 'index_cargo_metadata_on_project_normalized_name_version'

  def up
    with_lock_retries do
      create_table :packages_cargo_metadata, id: false do |t|
        t.references :package, primary_key: true, index: true, default: nil,
          foreign_key: { to_table: :packages_packages, on_delete: :cascade }, type: :bigint
        t.jsonb :index_content
        t.references :project, foreign_key: { on_delete: :cascade }, index: false, null: false
        t.text :normalized_name, limit: 64
        t.text :normalized_version, limit: 255

        t.timestamps_with_timezone null: false
      end
    end

    add_concurrent_index :packages_cargo_metadata,
      [:project_id, :normalized_name, :normalized_version],
      unique: true,
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index :packages_cargo_metadata,
      [:project_id, :normalized_name, :normalized_version],
      name: INDEX_NAME

    drop_table :packages_cargo_metadata
  end
end
