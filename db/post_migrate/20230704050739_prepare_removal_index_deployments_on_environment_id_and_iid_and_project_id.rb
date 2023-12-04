# frozen_string_literal: true

class PrepareRemovalIndexDeploymentsOnEnvironmentIdAndIidAndProjectId < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_deployments_on_environment_id_and_iid_and_project_id'

  def up
    prepare_async_index_removal :deployments, %i[environment_id iid project_id], name: INDEX_NAME
  end

  def down
    unprepare_async_index :deployments, %i[environment_id iid project_id], name: INDEX_NAME
  end
end
