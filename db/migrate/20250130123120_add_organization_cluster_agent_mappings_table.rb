# frozen_string_literal: true

class AddOrganizationClusterAgentMappingsTable < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  TABLE_NAME = :organization_cluster_agent_mappings
  UNIQUE_CLUSTER_AGENT_ID_INDEX_NAME = "i_organization_cluster_agent_mappings_unique_cluster_agent_id"
  CREATOR_ID_INDEX_NAME = "i_organization_cluster_agent_mappings_on_creator_id"
  ORGANIZATION_ID_INDEX_NAME = "i_organization_cluster_agent_mappings_on_organization_id"

  def up
    create_table TABLE_NAME, if_not_exists: true do |t|
      t.bigint :organization_id, null: false
      t.bigint :cluster_agent_id, null: false
      t.bigint :creator_id, null: true
      t.timestamps_with_timezone null: false
    end

    add_concurrent_index TABLE_NAME, :cluster_agent_id,
      unique: true, name: UNIQUE_CLUSTER_AGENT_ID_INDEX_NAME
    add_concurrent_index TABLE_NAME, :creator_id, name: CREATOR_ID_INDEX_NAME
    add_concurrent_index TABLE_NAME, :organization_id, name: ORGANIZATION_ID_INDEX_NAME

    add_concurrent_foreign_key TABLE_NAME, :cluster_agents, column: :cluster_agent_id, on_delete: :cascade
    add_concurrent_foreign_key TABLE_NAME, :organizations, column: :organization_id, on_delete: :cascade
    add_concurrent_foreign_key TABLE_NAME, :users, column: :creator_id, on_delete: :nullify
  end

  def down
    drop_table TABLE_NAME
  end
end
