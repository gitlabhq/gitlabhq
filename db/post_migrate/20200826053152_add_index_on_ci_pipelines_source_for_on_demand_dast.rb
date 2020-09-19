# frozen_string_literal: true

class AddIndexOnCiPipelinesSourceForOnDemandDast < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  INDEX_NAME = 'index_ci_pipelines_for_ondemand_dast_scans'

  SOURCE_ONDEMAND_DAST_SCAN_PIPELINE = 13

  disable_ddl_transaction!

  def up
    add_concurrent_index(
      :ci_pipelines, :id,
      where: "source = #{SOURCE_ONDEMAND_DAST_SCAN_PIPELINE}",
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index(
      :ci_pipelines, :id,
      where: "source = #{SOURCE_ONDEMAND_DAST_SCAN_PIPELINE}",
      name: INDEX_NAME
    )
  end
end
