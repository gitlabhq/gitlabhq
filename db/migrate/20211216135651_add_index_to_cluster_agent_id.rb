# frozen_string_literal: true

class AddIndexToClusterAgentId < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = "index_vulnerability_reads_on_cluster_agent_id"
  CLUSTER_IMAGE_SCANNING_REPORT_TYPE = 7

  def up
    add_concurrent_index :vulnerability_reads, :cluster_agent_id, where: "report_type = #{CLUSTER_IMAGE_SCANNING_REPORT_TYPE}", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :vulnerability_reads, INDEX_NAME
  end
end
