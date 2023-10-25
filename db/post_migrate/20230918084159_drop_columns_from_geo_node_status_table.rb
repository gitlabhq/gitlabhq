# frozen_string_literal: true

class DropColumnsFromGeoNodeStatusTable < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    [
      :wikis_checksum_failed_count,
      :wikis_checksum_mismatch_count,
      :wikis_checksummed_count,
      :wikis_failed_count,
      :wikis_retrying_verification_count,
      :wikis_synced_count,
      :wikis_verification_failed_count,
      :wikis_verified_count,
      :design_repositories_count,
      :design_repositories_synced_count,
      :design_repositories_failed_count,
      :design_repositories_registry_count
    ].each do |column_name|
      remove_column :geo_node_statuses, column_name, if_exists: true
    end
  end

  def down
    change_table(:geo_node_statuses) do |t|
      t.integer :wikis_checksum_failed_count
      t.integer :wikis_checksum_mismatch_count
      t.integer :wikis_checksummed_count
      t.integer :wikis_failed_count
      t.integer :wikis_retrying_verification_count
      t.integer :wikis_synced_count
      t.integer :wikis_verification_failed_count
      t.integer :wikis_verified_count
      t.integer :design_repositories_count
      t.integer :design_repositories_synced_count
      t.integer :design_repositories_failed_count
      t.integer :design_repositories_registry_count
    end
  end
end
