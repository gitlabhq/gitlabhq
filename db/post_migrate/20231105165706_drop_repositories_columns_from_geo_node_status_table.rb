# frozen_string_literal: true

class DropRepositoriesColumnsFromGeoNodeStatusTable < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '16.6'

  def up
    [
      :repositories_synced_count,
      :repositories_failed_count,
      :repositories_verified_count,
      :repositories_verification_failed_count,
      :repositories_checksummed_count,
      :repositories_checksum_failed_count,
      :repositories_checksum_mismatch_count,
      :repositories_retrying_verification_count
    ].each do |column_name|
      remove_column :geo_node_statuses, column_name, if_exists: true
    end
  end

  def down
    change_table(:geo_node_statuses) do |t|
      t.integer :repositories_synced_count
      t.integer :repositories_failed_count
      t.integer :repositories_verified_count
      t.integer :repositories_verification_failed_count
      t.integer :repositories_checksummed_count
      t.integer :repositories_checksum_failed_count
      t.integer :repositories_checksum_mismatch_count
      t.integer :repositories_retrying_verification_count
    end
  end
end
