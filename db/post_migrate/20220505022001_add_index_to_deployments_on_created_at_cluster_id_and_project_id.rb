# frozen_string_literal: true

class AddIndexToDeploymentsOnCreatedAtClusterIdAndProjectId < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  # This temporary index was created to support the script that will be run as part o this
  # Change Request: https://gitlab.com/gitlab-com/gl-infra/production/-/issues/6981
  #
  # Issue to remove the temporary index: https://gitlab.com/gitlab-org/gitlab/-/issues/361389
  INDEX_NAME = 'tp_index_created_at_cluster_id_project_id_on_deployments'

  # The change request will only run for deployments newer than this date. This is what we'll
  # be considering as "Active certificate based cluster Kubernetes Deployments". Namespaces with
  # deployments older than this will have to be migrated to the agent and won't have their
  # certificate based clusters life extended.
  DEPLOYMENTS_START_DATE = '2022-04-03 00:00:00'

  def up
    add_concurrent_index(
      :deployments,
      [:created_at, :cluster_id, :project_id],
      name: INDEX_NAME,
      where: "cluster_id is not null and created_at > '#{DEPLOYMENTS_START_DATE}'")
  end

  def down
    remove_concurrent_index_by_name(:deployments, INDEX_NAME)
  end
end
