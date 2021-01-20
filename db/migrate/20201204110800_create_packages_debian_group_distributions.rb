# frozen_string_literal: true

class CreatePackagesDebianGroupDistributions < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  UNIQUE_CODENAME = 'uniq_pkgs_debian_group_distributions_group_id_and_codename'
  UNIQUE_SUITE = 'uniq_pkgs_debian_group_distributions_group_id_and_suite'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      unless table_exists?(:packages_debian_group_distributions)
        create_table :packages_debian_group_distributions do |t|
          t.timestamps_with_timezone
          t.references :group, foreign_key: { to_table: :namespaces, on_delete: :restrict }, null: false
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

          t.index %w(group_id codename),
            name: UNIQUE_CODENAME,
            unique: true,
            using: :btree
          t.index %w(group_id suite),
            name: UNIQUE_SUITE,
            unique: true,
            using: :btree
        end
      end
    end

    add_text_limit :packages_debian_group_distributions, :codename, 255
    add_text_limit :packages_debian_group_distributions, :suite, 255
    add_text_limit :packages_debian_group_distributions, :origin, 255
    add_text_limit :packages_debian_group_distributions, :label, 255
    add_text_limit :packages_debian_group_distributions, :version, 255
    add_text_limit :packages_debian_group_distributions, :description, 255
    add_text_limit :packages_debian_group_distributions, :encrypted_signing_keys, 2048
    add_text_limit :packages_debian_group_distributions, :encrypted_signing_keys_iv, 255
    add_text_limit :packages_debian_group_distributions, :file, 255
    add_text_limit :packages_debian_group_distributions, :file_signature, 4096
  end

  def down
    drop_table :packages_debian_group_distributions
  end
end
