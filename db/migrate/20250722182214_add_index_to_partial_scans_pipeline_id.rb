# frozen_string_literal: true

class AddIndexToPartialScansPipelineId < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  disable_ddl_transaction!

  INDEX_NAME = 'index_vulnerability_partial_scans_on_pipeline_id'

  def up
    add_concurrent_index :vulnerability_partial_scans, :pipeline_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :vulnerability_partial_scans, INDEX_NAME
  end
end
