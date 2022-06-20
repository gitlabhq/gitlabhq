# frozen_string_literal: true

class AddIndexOnClustersAgentProjectIdAndHasVulnerabilitiesColumns < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_cluster_agents_on_project_id_and_has_vulnerabilities'

  def up
    add_concurrent_index :cluster_agents,
                         [:project_id, :has_vulnerabilities],
                         name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :cluster_agents, INDEX_NAME
  end
end
