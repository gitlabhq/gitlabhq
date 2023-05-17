# frozen_string_literal: true

class DropIndexSecurityScansOnPipelineId < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_security_scans_on_pipeline_id'

  disable_ddl_transaction!

  def up
    remove_concurrent_index :security_scans, :pipeline_id, name: INDEX_NAME
  end

  def down
    add_concurrent_index :security_scans, :pipeline_id, name: INDEX_NAME
  end
end
