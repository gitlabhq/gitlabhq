# frozen_string_literal: true

class DropIndexOnDeploymentsOnCreatedAtClusterIdAndProjectId < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'tp_index_created_at_cluster_id_project_id_on_deployments'

  def up
    remove_concurrent_index_by_name :deployments, INDEX_NAME
  end

  def down
    # no-op
    #
    # There's no need to re-add this index as it's purpose was temporary, served only
    # for a specific CR query which is now closed, and should not be re-opened.
  end
end
