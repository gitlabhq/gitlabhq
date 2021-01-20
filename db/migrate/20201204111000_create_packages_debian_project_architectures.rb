# frozen_string_literal: true

class CreatePackagesDebianProjectArchitectures < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  INDEX_NAME = 'idx_pkgs_deb_proj_architectures_on_distribution_id'
  UNIQUE_NAME = 'uniq_pkgs_deb_proj_architectures_on_distribution_id_and_name'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      unless table_exists?(:packages_debian_project_architectures)
        create_table :packages_debian_project_architectures do |t|
          t.timestamps_with_timezone
          t.references :distribution,
            foreign_key: { to_table: :packages_debian_project_distributions, on_delete: :cascade },
            null: false,
            index: { name: INDEX_NAME }
          t.text :name, null: false

          t.index %w(distribution_id name),
            name: UNIQUE_NAME,
            unique: true,
            using: :btree
        end
      end
    end

    add_text_limit :packages_debian_project_architectures, :name, 255
  end

  def down
    drop_table :packages_debian_project_architectures
  end
end
