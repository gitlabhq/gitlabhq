# frozen_string_literal: true

class CreatePackagesDebianGroupComponents < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  UNIQUE_NAME = 'uniq_pkgs_deb_grp_components_on_distribution_id_and_name'

  disable_ddl_transaction!

  def up
    unless table_exists?(:packages_debian_group_components)
      create_table :packages_debian_group_components do |t|
        t.timestamps_with_timezone
        t.references :distribution,
          foreign_key: { to_table: :packages_debian_group_distributions, on_delete: :cascade },
          null: false,
          index: false
        t.text :name, null: false

        t.index %w(distribution_id name),
          name: UNIQUE_NAME,
          unique: true,
          using: :btree
      end
    end

    add_text_limit :packages_debian_group_components, :name, 255
  end

  def down
    drop_table :packages_debian_group_components
  end
end
