# frozen_string_literal: true

class CreatePackagesDebianProjectDistributions < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  UNIQUE_CODENAME = 'uniq_pkgs_debian_project_distributions_project_id_and_codename'
  UNIQUE_SUITE = 'uniq_pkgs_debian_project_distributions_project_id_and_suite'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      unless table_exists?(:packages_debian_project_distributions)
        create_table :packages_debian_project_distributions do |t|
          t.timestamps_with_timezone
          t.references :project, foreign_key: { to_table: :projects, on_delete: :restrict }, null: false
          t.references :creator, foreign_key: { to_table: :users, on_delete: :nullify }
          t.integer :valid_time_duration_seconds
          t.integer :file_store, limit: 2, default: 1, null: false
          t.boolean :automatic, default: true, null: false
          t.boolean :automatic_upgrades, default: false, null: false
          t.text :codename, null: false
          t.text :suite
          t.text :origin
          t.text :label
          t.text :version
          t.text :description
          t.text :encrypted_signing_keys
          t.text :encrypted_signing_keys_iv
          t.text :file
          t.text :file_signature

          t.index %w(project_id codename),
            name: UNIQUE_CODENAME,
            unique: true,
            using: :btree
          t.index %w(project_id suite),
            name: UNIQUE_SUITE,
            unique: true,
            using: :btree
        end
      end
    end

    add_text_limit :packages_debian_project_distributions, :codename, 255
    add_text_limit :packages_debian_project_distributions, :suite, 255
    add_text_limit :packages_debian_project_distributions, :origin, 255
    add_text_limit :packages_debian_project_distributions, :label, 255
    add_text_limit :packages_debian_project_distributions, :version, 255
    add_text_limit :packages_debian_project_distributions, :description, 255
    add_text_limit :packages_debian_project_distributions, :encrypted_signing_keys, 2048
    add_text_limit :packages_debian_project_distributions, :encrypted_signing_keys_iv, 255
    add_text_limit :packages_debian_project_distributions, :file, 255
    add_text_limit :packages_debian_project_distributions, :file_signature, 4096
  end

  def down
    drop_table :packages_debian_project_distributions
  end
end
