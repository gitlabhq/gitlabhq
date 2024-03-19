# frozen_string_literal: true

class CreateRdNamespaceClusterAgentMappingsTable < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.10'

  TABLE_NAME = :remote_development_namespace_cluster_agent_mappings
  UNIQUE_NAMESPACE_CLUSTER_AGENT_INDEX_NAME = "unique_namespace_cluster_agent_mappings_for_agent_association"
  CLUSTER_AGENT_INDEX_NAME = "i_namespace_cluster_agent_mappings_on_cluster_agent_id"
  CREATOR_ID_INDEX_NAME = "i_namespace_cluster_agent_mappings_on_creator_id"

  def up
    unless table_exists?(TABLE_NAME)
      create_table TABLE_NAME do |t|
        t.timestamps_with_timezone null: false
        t.bigint :namespace_id, null: false
        t.bigint :cluster_agent_id, null: false
        t.bigint :creator_id, null: true
      end
    end

    add_concurrent_index TABLE_NAME, [:namespace_id, :cluster_agent_id],
      unique: true, name: UNIQUE_NAMESPACE_CLUSTER_AGENT_INDEX_NAME

    # The indices below have been added for the sake of making cascade updates faster for the involved
    # foreign key columns
    add_concurrent_index TABLE_NAME, :cluster_agent_id, name: CLUSTER_AGENT_INDEX_NAME
    add_concurrent_index TABLE_NAME, :creator_id, name: CREATOR_ID_INDEX_NAME
  end

  def down
    drop_table TABLE_NAME
  end
end
