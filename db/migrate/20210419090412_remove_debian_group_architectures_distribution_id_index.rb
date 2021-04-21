# frozen_string_literal: true

class RemoveDebianGroupArchitecturesDistributionIdIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  INDEX_NAME = 'idx_pkgs_deb_grp_architectures_on_distribution_id'

  disable_ddl_transaction!

  def up
    remove_concurrent_index :packages_debian_group_architectures, :distribution_id, name: INDEX_NAME
  end

  def down
    add_concurrent_index :packages_debian_group_architectures, :distribution_id, name: INDEX_NAME
  end
end
