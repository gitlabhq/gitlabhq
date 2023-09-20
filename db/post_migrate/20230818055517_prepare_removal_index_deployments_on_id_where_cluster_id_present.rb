# frozen_string_literal: true

class PrepareRemovalIndexDeploymentsOnIdWhereClusterIdPresent < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_deployments_on_id_where_cluster_id_present'

  # TODO: Index to be destroyed synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/402510
  def up
    prepare_async_index_removal :deployments, :id, name: INDEX_NAME
  end

  def down
    unprepare_async_index :deployments, :id, name: INDEX_NAME
  end
end
