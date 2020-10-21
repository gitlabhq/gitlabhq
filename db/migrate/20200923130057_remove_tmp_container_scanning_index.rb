# frozen_string_literal: true

class RemoveTmpContainerScanningIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'tmp_index_for_fixing_inconsistent_vulnerability_occurrences'
  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name(:vulnerability_occurrences, INDEX_NAME)
  end

  def down
    # report_type: 2 container scanning
    add_concurrent_index(:vulnerability_occurrences, :id,
      where: "LENGTH(location_fingerprint) = 40 AND report_type = 2",
      name: INDEX_NAME)
  end
end
