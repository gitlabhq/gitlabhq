# frozen_string_literal: true

class CreatePackagesDebianProjectComponentFiles < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  INDEX_ARCHITECTURE = 'idx_packages_debian_project_component_files_on_architecture_id'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      unless table_exists?(:packages_debian_project_component_files)
        create_table :packages_debian_project_component_files do |t|
          t.timestamps_with_timezone
          t.references :component,
            foreign_key: { to_table: :packages_debian_project_components, on_delete: :restrict },
            null: false,
            index: true
          t.references :architecture,
            foreign_key: { to_table: :packages_debian_project_architectures, on_delete: :restrict },
            index: { name: INDEX_ARCHITECTURE }
          t.integer :size, null: false
          t.integer :file_type, limit: 2, null: false
          t.integer :compression_type, limit: 2
          t.integer :file_store, limit: 2, default: 1, null: false
          t.text :file, null: false
          t.binary :file_md5, null: false
          t.binary :file_sha256, null: false
        end
      end
    end

    add_text_limit :packages_debian_project_component_files, :file, 255
  end

  def down
    drop_table :packages_debian_project_component_files
  end
end
