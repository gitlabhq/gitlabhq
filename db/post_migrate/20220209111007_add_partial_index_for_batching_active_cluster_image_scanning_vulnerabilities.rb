# frozen_string_literal: true

class AddPartialIndexForBatchingActiveClusterImageScanningVulnerabilities < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_vulnerabilities_on_project_id_and_id_active_cis'
  INDEX_FILTER_CONDITION = 'report_type = 7 AND state = ANY(ARRAY[1, 4])'

  disable_ddl_transaction!

  def up
    add_concurrent_index :vulnerabilities, [:project_id, :id], where: INDEX_FILTER_CONDITION, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :vulnerabilities, [:project_id, :id], name: INDEX_NAME
  end
end
