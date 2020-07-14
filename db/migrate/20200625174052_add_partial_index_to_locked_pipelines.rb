# frozen_string_literal: true

class AddPartialIndexToLockedPipelines < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_pipelines, [:ci_ref_id, :id], name: 'idx_ci_pipelines_artifacts_locked', where: 'locked = 1'
  end

  def down
    remove_concurrent_index :ci_pipelines, 'idx_ci_pipelines_artifacts_locked'
  end
end
