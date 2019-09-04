# frozen_string_literal: true

class AddIndexForCiBuildsMetrics < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'ci_builds_gitlab_monitor_metrics'

  def up
    add_concurrent_index(:ci_builds, [:status, :created_at, :project_id], where: "type = 'Ci::Build'", name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(:ci_builds, INDEX_NAME)
  end
end
