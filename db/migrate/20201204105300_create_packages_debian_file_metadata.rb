# frozen_string_literal: true

class CreatePackagesDebianFileMetadata < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless table_exists?(:packages_debian_file_metadata)
      create_table :packages_debian_file_metadata, id: false do |t|
        t.timestamps_with_timezone
        t.references :package_file, primary_key: true, index: false, default: nil, null: false, foreign_key: { to_table: :packages_package_files, on_delete: :cascade }, type: :bigint
        t.integer :file_type, limit: 2, null: false
        t.text :component
        t.text :architecture
        t.jsonb :fields
      end
    end

    add_text_limit :packages_debian_file_metadata, :component, 255
    add_text_limit :packages_debian_file_metadata, :architecture, 255
  end

  def down
    drop_table :packages_debian_file_metadata
  end
end
