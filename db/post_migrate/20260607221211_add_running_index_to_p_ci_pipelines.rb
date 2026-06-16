# frozen_string_literal: true

class AddRunningIndexToPCiPipelines < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '19.1'

  INDEX_NAME = 'index_running_ci_pipelines_on_updated_at_and_id'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- https://gitlab.com/gitlab-org/database-team/team-tasks/-/work_items/615
    add_concurrent_partitioned_index :p_ci_pipelines, [:updated_at, :id], where: "status = 'running'", name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_partitioned_index_by_name :p_ci_pipelines, INDEX_NAME
  end
end
