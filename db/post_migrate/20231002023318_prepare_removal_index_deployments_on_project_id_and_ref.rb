# frozen_string_literal: true

class PrepareRemovalIndexDeploymentsOnProjectIdAndRef < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_deployments_on_project_id_and_ref'

  # TODO: Index to be destroyed synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/402511
  def up
    prepare_async_index_removal :deployments, %i[project_id ref], name: INDEX_NAME
  end

  def down
    unprepare_async_index :deployments, %i[project_id ref], name: INDEX_NAME
  end
end
