# frozen_string_literal: true

class AddNotValidForeignKeyToCycleAnalyticsGroupStages < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  CONSTRAINT_NAME = 'fk_analytics_cycle_analytics_group_stages_group_value_stream_id'
  INDEX_NAME = 'index_analytics_ca_group_stages_on_value_stream_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :analytics_cycle_analytics_group_stages, :group_value_stream_id, name: INDEX_NAME
    add_foreign_key :analytics_cycle_analytics_group_stages, :analytics_cycle_analytics_group_value_streams,
      column: :group_value_stream_id, name: CONSTRAINT_NAME, on_delete: :cascade, validate: false
  end

  def down
    remove_foreign_key_if_exists :analytics_cycle_analytics_group_stages, column: :group_value_stream_id, name: CONSTRAINT_NAME
    remove_concurrent_index :analytics_cycle_analytics_group_stages, :group_value_stream_id
  end
end
