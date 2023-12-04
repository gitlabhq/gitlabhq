# frozen_string_literal: true

class PrepareRemovalIndexSuccessDeploymentsOnClusterIdAndEnvironmentId < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_successful_deployments_on_cluster_id_and_environment_id'

  # TODO: Index to be destroyed synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/402514
  def up
    prepare_async_index_removal :deployments, %i[cluster_id environment_id], name: INDEX_NAME
  end

  def down
    unprepare_async_index :deployments, %i[cluster_id environment_id], name: INDEX_NAME
  end
end
