# frozen_string_literal: true

class AddOwnerAndIdIndexOnActiveCiPipelineSchedules < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_ci_pipeline_schedules_on_owner_id_and_id_and_active'

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_pipeline_schedules, [:owner_id, :id], where: "active = TRUE", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_pipeline_schedules, INDEX_NAME
  end
end
