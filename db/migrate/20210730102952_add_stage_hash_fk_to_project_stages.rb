# frozen_string_literal: true

class AddStageHashFkToProjectStages < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    unless column_exists?(:analytics_cycle_analytics_project_stages, :stage_event_hash_id)
      add_column :analytics_cycle_analytics_project_stages, :stage_event_hash_id, :bigint
    end

    add_concurrent_index :analytics_cycle_analytics_project_stages, :stage_event_hash_id, name: 'index_project_stages_on_stage_event_hash_id'
    add_concurrent_foreign_key :analytics_cycle_analytics_project_stages, :analytics_cycle_analytics_stage_event_hashes, column: :stage_event_hash_id, on_delete: :cascade
  end

  def down
    remove_column :analytics_cycle_analytics_project_stages, :stage_event_hash_id
  end
end
